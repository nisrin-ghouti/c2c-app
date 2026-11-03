-- Which organizer names each host is allowed to put on an event.
--
-- `0068` turned Organizer Name from free text into a curated
-- `option_lists` list, but every host could still pick any entry on it. This
-- adds the missing half: an admin assigns a subset of organizer names to each
-- host, and that host may only use those.
--
-- Shape:
--   * `host_organizer_access` — the assignment table, one row per
--     (host, organizer) pair.
--   * `admin_list_host_organizers` / `admin_set_host_organizers` — the admin
--     console's read/write for managing a host's assignments.
--   * `list_my_organizer_options` — what the signed-in user may choose from,
--     which is what the event form's dropdown is built from.
--   * A trigger on `events` enforcing the same rule server-side, so the
--     restriction holds even if the form is bypassed.
--
-- The trigger is deliberately a trigger rather than a rewrite of
-- `create_event_or_program` / `update_event_or_program`. Those functions have
-- been redefined five times across 0020 → 0057 and their current bodies live
-- only in the live database; re-declaring them here to add six lines would
-- risk reverting whatever else has changed in them. A trigger covers every
-- write path — both RPCs, direct table writes, and anything added later —
-- without touching them.
--
-- Data preservation, which the spec calls out explicitly:
--   * Events already carrying an organizer name keep it. The trigger only
--     objects when `organizer_name` is actually being *set or changed*, so a
--     host editing an old event's location or time is never blocked by an
--     organizer they were never assigned.
--   * No existing row is modified and nothing is deleted.
--
-- Depends on 0068 (the `event_organizer` list type). Numbered 0079 because
-- 0073-0078 were taken by other work before this landed.

-- ---------------------------------------------------------------------------
-- 1. The assignment table
-- ---------------------------------------------------------------------------
-- Keyed on the option_lists row rather than on its label text, so renaming an
-- organizer in Possible Lists carries the assignments with it and deleting one
-- cleans them up.
create table if not exists public.host_organizer_access (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles(id)     on delete cascade,
  option_list_id uuid not null references public.option_lists(id) on delete cascade,
  granted_by     uuid references auth.users(id) on delete set null,
  granted_at     timestamptz not null default now(),
  unique (user_id, option_list_id)
);

create index if not exists host_organizer_access_user_idx
  on public.host_organizer_access (user_id);

-- SELECT only; every write goes through the admin-gated RPCs below.
grant select on public.host_organizer_access to authenticated;

alter table public.host_organizer_access enable row level security;

-- A user may see their own assignments; admins may see all.
drop policy if exists host_organizer_access_select on public.host_organizer_access;
create policy host_organizer_access_select
  on public.host_organizer_access
  for select
  to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------------
-- 2. What the signed-in user may choose from
-- ---------------------------------------------------------------------------
-- Admins get the whole active list — they curate it, and restricting the
-- people who manage the list to a subset of it makes no sense.
--
-- Everyone else gets exactly their assignments, and nothing when they have
-- none. That is the spec's rule read literally ("only ... names that have been
-- explicitly assigned"), and it means a host with no assignments sees an empty
-- dropdown until an admin gives them one. Worth knowing before rollout: assign
-- organizers to your existing hosts, or they will not be able to set an
-- organizer on a *new* event. Editing their existing events is unaffected —
-- see the trigger below.
create or replace function public.list_my_organizer_options()
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    return '[]'::jsonb;
  end if;

  if public.is_admin() then
    return coalesce(
      (
        select jsonb_agg(jsonb_build_object(
          'id',       o.id,
          'label',    o.label,
          'label_he', o.label_he,
          'label_ar', o.label_ar
        ) order by o.sort_order, o.label)
        from public.option_lists o
        where o.list_type = 'event_organizer'
          and o.active
      ),
      '[]'::jsonb
    );
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'id',       o.id,
        'label',    o.label,
        'label_he', o.label_he,
        'label_ar', o.label_ar
      ) order by o.sort_order, o.label)
      from public.host_organizer_access a
      join public.option_lists o on o.id = a.option_list_id
      where a.user_id = auth.uid()
        and o.list_type = 'event_organizer'
        and o.active
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.list_my_organizer_options() from public;
grant execute on function public.list_my_organizer_options() to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Admin: read a host's assignments
-- ---------------------------------------------------------------------------
-- Returns every active organizer option with an `assigned` flag, rather than
-- just the assigned ones, so the admin console can render the full checkbox
-- list from a single call.
create or replace function public.admin_list_host_organizers(
  _user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
begin
  if not public.is_admin() then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'id',       o.id,
        'label',    o.label,
        'label_he', o.label_he,
        'label_ar', o.label_ar,
        'assigned', exists (
          select 1 from public.host_organizer_access a
          where a.user_id = _user_id
            and a.option_list_id = o.id
        )
      ) order by o.sort_order, o.label)
      from public.option_lists o
      where o.list_type = 'event_organizer'
        and o.active
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.admin_list_host_organizers(uuid) from public;
grant execute on function public.admin_list_host_organizers(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Admin: replace a host's assignments
-- ---------------------------------------------------------------------------
-- Takes the complete desired set and makes the table match it, so the console
-- can send the checkbox state as-is instead of diffing. Deletes first, then
-- inserts, inside the one statement pair that makes up the function call —
-- a reader never observes a partially applied set.
create or replace function public.admin_set_host_organizers(
  _user_id    uuid,
  _option_ids uuid[]
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _count int;
begin
  if not public.is_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if not exists (select 1 from public.profiles where id = _user_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  delete from public.host_organizer_access
  where user_id = _user_id
    and (
      _option_ids is null
      or cardinality(_option_ids) = 0
      or option_list_id <> all (_option_ids)
    );

  if _option_ids is not null and cardinality(_option_ids) > 0 then
    insert into public.host_organizer_access (user_id, option_list_id, granted_by)
    select _user_id, ids.option_id, auth.uid()
    from (select distinct unnest(_option_ids) as option_id) as ids
    -- Only real `event_organizer` rows; a stale or wrong-typed id is skipped
    -- rather than failing the whole call.
    where exists (
      select 1 from public.option_lists o
      where o.id = ids.option_id
        and o.list_type = 'event_organizer'
    )
    on conflict (user_id, option_list_id) do nothing;
  end if;

  select count(*) into _count
  from public.host_organizer_access
  where user_id = _user_id;

  return jsonb_build_object('status', 'ok', 'assigned', _count);
end;
$$;

revoke all on function public.admin_set_host_organizers(uuid, uuid[]) from public;
grant execute on function public.admin_set_host_organizers(uuid, uuid[]) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Server-side enforcement
-- ---------------------------------------------------------------------------
-- The frontend hides disallowed names; this makes hiding them irrelevant.
--
-- Only fires when `organizer_name` is actually being set or changed. That is
-- what keeps existing data working: a host editing an event whose organizer
-- was assigned before this feature existed — or assigned to someone else — can
-- still change its title, location and times without the write being refused
-- over a field they did not touch.
create or replace function public.enforce_host_organizer_access()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _name text;
begin
  _name := nullif(btrim(coalesce(new.organizer_name, '')), '');

  -- No organizer set: nothing to authorize. Organizer Name is optional.
  if _name is null then
    return new;
  end if;

  -- Unchanged on update: not this write's business.
  if tg_op = 'UPDATE'
     and btrim(coalesce(old.organizer_name, '')) = btrim(coalesce(new.organizer_name, ''))
  then
    return new;
  end if;

  -- No authenticated caller — a migration, a seed, or a service-role job.
  -- There is no one to authorize, so don't invent a denial.
  if auth.uid() is null then
    return new;
  end if;

  if public.is_admin() then
    return new;
  end if;

  if exists (
    select 1
    from public.host_organizer_access a
    join public.option_lists o on o.id = a.option_list_id
    where a.user_id = auth.uid()
      and o.list_type = 'event_organizer'
      and o.label = _name
  ) then
    return new;
  end if;

  raise exception
    'Organizer name % is not assigned to this account', _name
    using errcode = 'check_violation';
end;
$$;

drop trigger if exists trg_enforce_host_organizer_access on public.events;
create trigger trg_enforce_host_organizer_access
  before insert or update of organizer_name on public.events
  for each row
  execute function public.enforce_host_organizer_access();

-- ---------------------------------------------------------------------------
-- 6. Which hosts still have nothing assigned
-- ---------------------------------------------------------------------------
-- Printed, not acted on. These accounts will see an empty Organizer Name
-- dropdown until an admin assigns them something — assign before announcing
-- the feature. Admins are excluded; they always get the full list.
do $$
declare
  _u record;
  _any boolean := false;
begin
  for _u in
    select p.id, coalesce(nullif(btrim(p.full_name), ''), p.email) as who
    from public.profiles p
    join public.user_roles r on r.user_id = p.id and r.role = 'host'
    where not exists (
      select 1 from public.user_roles ar
      where ar.user_id = p.id and ar.role = 'admin'
    )
    and not exists (
      select 1 from public.host_organizer_access a where a.user_id = p.id
    )
  loop
    if not _any then
      raise notice 'Hosts with no organizer names assigned:';
      _any := true;
    end if;
    raise notice '  % (%)', _u.who, _u.id;
  end loop;

  if not _any then
    raise notice 'Every host has at least one organizer name assigned.';
  end if;
end $$;
