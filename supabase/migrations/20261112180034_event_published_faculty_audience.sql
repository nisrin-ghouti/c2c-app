-- "New event" notifications follow the event's audience.
--
-- `notify_event_published` (0075) calls `notify_all_students`, so an event
-- saved as `specific_faculties` still pushed the whole campus. Students then
-- opened a notification for an event `event_is_visible_to` (0084) hides from
-- them. Faculty is the case people reported; a degree restriction on the same
-- event is applied too, with the same AND rule as visibility: faculty rows
-- only, degree rows only, or both. No target rows at all stays "everyone",
-- which is what 0084 does for a restricted event that never stored targets.
-- `only_me` has no student audience, so it no longer fans out either.
-- `everyone` and the retired `specific_groups` value are unchanged.
--
-- The fan-out cannot run at INSERT time. `create_event_or_program` inserts
-- the event first and `event_visibility_targets` afterwards, and an admin or
-- group manager is already `approved` by `auto_approve_admin_events` before
-- that insert returns. A statement-level AFTER trigger therefore sees an
-- approved event and zero targets, and would still notify everyone. The same
-- fix surveys used in 0074: a deferrable constraint trigger, so this runs at
-- COMMIT, after the targets exist. A host event stays `pending` on insert and
-- notifies later, when approval changes; by then the targets are already
-- stored, and the same function handles both.
--
-- An admin or group-manager edit stays approved (0056, 0082), so it never
-- passes through that approval step. Opening the audience on that save —
-- Only me to Everyone, Only me to one faculty, one faculty to another —
-- notifies the students who can now see the event and could not before.
-- Someone who was already in the audience is not told again, and a title or
-- time change does not send another "New event". A host edit still goes back
-- to pending, and the later approval notifies the current audience once.
--
-- The payload is the 0075 one (`title` plus `title_en` / `title_he` /
-- `title_ar`), and the creator is still excluded.
--
-- A failure here must not roll back the event. This trigger runs at COMMIT,
-- after `create_event_or_program` has already built its `{"status":"ok"}`
-- reply; an exception escaping it would fail that save. The insert sits in
-- its own block so a failed fan-out undoes only the notification rows.

-- ---------------------------------------------------------------------------
-- Previous audience
-- ---------------------------------------------------------------------------
-- `update_event_or_program` updates the event, then deletes and reinserts
-- `event_visibility_targets`. By commit time the old faculty rows are gone,
-- so a BEFORE UPDATE trigger copies them first. The first snapshot in a
-- transaction wins: a later statement in the same transaction must not
-- overwrite it with the targets it just wrote.

create or replace function public.remember_event_audience()
returns trigger
language plpgsql
security definer
set search_path to public, pg_temp
as $$
begin
  create temp table if not exists event_audience_snapshotted (
    event_id uuid primary key
  ) on commit drop;

  create temp table if not exists event_audience_before (
    event_id uuid,
    target_type text,
    target_value text
  ) on commit drop;

  insert into pg_temp.event_audience_snapshotted (event_id)
  values (old.id)
  on conflict (event_id) do nothing;

  if found then
    insert into pg_temp.event_audience_before (event_id, target_type, target_value)
    select old.id, t.target_type, t.target_value
    from public.event_visibility_targets t
    where t.event_id = old.id;
  end if;

  return new;
end;
$$;

revoke all on function public.remember_event_audience() from public;

drop trigger if exists trg_remember_event_audience on public.events;
create trigger trg_remember_event_audience
  before update on public.events
  for each row
  execute function public.remember_event_audience();

-- True when this transaction replaced the event's faculty/degree rows.
-- plpgsql plus EXECUTE: a SQL function is checked at creation, and these
-- temp tables do not exist until an event is edited.
create or replace function public.event_audience_targets_changed(_event_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path to public, pg_temp
as $$
declare
  _changed boolean;
begin
  if to_regclass('pg_temp.event_audience_snapshotted') is null then
    return false;
  end if;

  execute $q$
    select
      exists (
        select 1 from pg_temp.event_audience_snapshotted where event_id = $1
      )
      and (
        exists (
          select target_type, target_value
          from pg_temp.event_audience_before
          where event_id = $1
          except
          select target_type, target_value
          from public.event_visibility_targets
          where event_id = $1
        )
        or exists (
          select target_type, target_value
          from public.event_visibility_targets
          where event_id = $1
          except
          select target_type, target_value
          from pg_temp.event_audience_before
          where event_id = $1
        )
      )
  $q$
  into _changed
  using _event_id;

  return coalesce(_changed, false);
end;
$$;

revoke all on function public.event_audience_targets_changed(uuid) from public;

-- Whether this profile could already see the event under the audience it
-- had at the start of the transaction. `only_me` matches nobody. Anything
-- other than `specific_faculties` matches every profile. Faculty and degree
-- use the same AND rule as `event_is_visible_to`.
create or replace function public.profile_was_in_event_audience(
  _user_id uuid,
  _visibility text,
  _event_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path to public, pg_temp
as $$
declare
  _has_faculty boolean;
  _has_degree boolean;
  _faculty_ok boolean;
  _degree_ok boolean;
  _use_snapshot boolean;
begin
  if coalesce(_visibility, 'everyone') = 'only_me' then
    return false;
  end if;

  if coalesce(_visibility, 'everyone') <> 'specific_faculties' then
    return true;
  end if;

  _use_snapshot :=
    to_regclass('pg_temp.event_audience_snapshotted') is not null
    and exists (
      select 1 from pg_temp.event_audience_snapshotted where event_id = _event_id
    );

  if _use_snapshot then
    select
      exists (
        select 1 from pg_temp.event_audience_before
        where event_id = _event_id and target_type = 'faculty'
      ),
      exists (
        select 1 from pg_temp.event_audience_before
        where event_id = _event_id and target_type = 'degree'
      )
    into _has_faculty, _has_degree;

    _faculty_ok := not _has_faculty or exists (
      select 1
      from public.profiles p
      join pg_temp.event_audience_before t
        on t.event_id = _event_id
       and t.target_type = 'faculty'
       and (
         t.target_value = any (coalesce(p.faculties, '{}'::text[]))
         or t.target_value = p.faculty
       )
      where p.id = _user_id
    );

    _degree_ok := not _has_degree or exists (
      select 1
      from public.profiles p
      join pg_temp.event_audience_before t
        on t.event_id = _event_id
       and t.target_type = 'degree'
       and t.target_value = p.degree
      where p.id = _user_id
    );
  else
    select
      exists (
        select 1 from public.event_visibility_targets
        where event_id = _event_id and target_type = 'faculty'
      ),
      exists (
        select 1 from public.event_visibility_targets
        where event_id = _event_id and target_type = 'degree'
      )
    into _has_faculty, _has_degree;

    _faculty_ok := not _has_faculty or exists (
      select 1
      from public.profiles p
      join public.event_visibility_targets t
        on t.event_id = _event_id
       and t.target_type = 'faculty'
       and (
         t.target_value = any (coalesce(p.faculties, '{}'::text[]))
         or t.target_value = p.faculty
       )
      where p.id = _user_id
    );

    _degree_ok := not _has_degree or exists (
      select 1
      from public.profiles p
      join public.event_visibility_targets t
        on t.event_id = _event_id
       and t.target_type = 'degree'
       and t.target_value = p.degree
      where p.id = _user_id
    );
  end if;

  return _faculty_ok and _degree_ok;
end;
$$;

revoke all on function public.profile_was_in_event_audience(uuid, text, uuid) from public;

-- ---------------------------------------------------------------------------
-- The fan-out
-- ---------------------------------------------------------------------------
create or replace function public.notify_event_published()
returns trigger
language plpgsql
security definer
set search_path to public, pg_temp
as $$
declare
  _event public.events%rowtype;
  _audience_edit boolean := false;
begin
  -- An edit that leaves the event approved. Admin and group-manager saves
  -- take this path. Notify only when it changes who can see the event.
  if tg_op = 'UPDATE'
     and old.approval_status is not distinct from new.approval_status then
    if old.visibility is not distinct from new.visibility
       and not public.event_audience_targets_changed(new.id) then
      return new;
    end if;
    _audience_edit := true;
  end if;

  if new.approval_status is distinct from 'approved' then
    return new;
  end if;

  begin
    -- Re-read at commit time. NEW is the row from the statement that fired
    -- this trigger; the targets, and any same-transaction change to
    -- visibility, live on the table by now.
    select * into _event from public.events where id = new.id;
    if not found or _event.approval_status is distinct from 'approved' then
      return new;
    end if;

    if coalesce(_event.visibility, 'everyone') = 'only_me' then
      return new;
    end if;

    insert into public.notifications (user_id, type, data)
    select
      p.id,
      'event_published',
      jsonb_build_object(
        'event_id',  _event.id,
        'title',     _event.title,
        'title_en',  _event.title_en,
        'title_he',  _event.title_he,
        'title_ar',  _event.title_ar,
        'starts_at', _event.starts_at,
        'points',    _event.points
      )
    from public.profiles p
    where p.deleted_at is null
      and (_event.created_by is null or p.id <> _event.created_by)
      and (
        not _audience_edit
        or not public.profile_was_in_event_audience(
          p.id, old.visibility, _event.id
        )
      )
      and (
        coalesce(_event.visibility, 'everyone') <> 'specific_faculties'
        or (
          (
            not exists (
              select 1
              from public.event_visibility_targets t
              where t.event_id = _event.id
                and t.target_type = 'faculty'
            )
            or exists (
              select 1
              from public.event_visibility_targets t
              where t.event_id = _event.id
                and t.target_type = 'faculty'
                and (
                  t.target_value = any (coalesce(p.faculties, '{}'::text[]))
                  or t.target_value = p.faculty
                )
            )
          )
          and (
            not exists (
              select 1
              from public.event_visibility_targets t
              where t.event_id = _event.id
                and t.target_type = 'degree'
            )
            or exists (
              select 1
              from public.event_visibility_targets t
              where t.event_id = _event.id
                and t.target_type = 'degree'
                and t.target_value = p.degree
            )
          )
        )
      );
  exception when others then
    raise warning 'event_published fan-out failed for event % (%): %',
      new.id, sqlstate, sqlerrm;
  end;

  return new;
end;
$$;

-- The statement-time trigger from 0075 fires before the faculty rows exist.
drop trigger if exists trg_notify_event_published on public.events;

do $$
begin
  execute 'drop trigger if exists trg_notify_event_published_deferred on public.events';
  execute $trg$
    create constraint trigger trg_notify_event_published_deferred
      after insert or update on public.events
      deferrable initially deferred
      for each row
      execute function public.notify_event_published()
  $trg$;
end $$;
