-- Personalised groups: a host or admin builds a list of people by email,
-- then an event or program can be visible only to the groups they pick.
--
-- `specific_groups` was stored but never enforced (0069 treated it as
-- everyone). It now means "member of one of the attached audience groups".
-- The attachment is an `event_visibility_targets` row with
-- target_type = 'audience_group' and the group id as target_value, the
-- same table faculties and degrees already use.

create table if not exists public.audience_groups (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint audience_groups_name_not_blank check (length(btrim(name)) > 0)
);

create table if not exists public.audience_group_members (
  group_id uuid not null references public.audience_groups (id) on delete cascade,
  user_id  uuid not null references public.profiles (id) on delete cascade,
  added_by uuid references public.profiles (id) on delete set null,
  added_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create index if not exists audience_group_members_user_idx
  on public.audience_group_members (user_id);

alter table public.audience_groups enable row level security;
alter table public.audience_group_members enable row level security;

-- No table grants. Every read and write goes through the functions below,
-- which is what keeps a host inside the groups they created.

create or replace function public._caller_is_host_or_admin()
returns boolean
language sql
stable
security definer
set search_path to public
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and role in ('host', 'admin')
  );
$$;

revoke all on function public._caller_is_host_or_admin() from public;

create or replace function public._can_edit_audience_group(_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path to public
as $$
  select public._caller_is_host_or_admin()
    and (
      exists (
        select 1 from public.user_roles
        where user_id = auth.uid() and role = 'admin'
      )
      or exists (
        select 1 from public.audience_groups g
        where g.id = _group_id and g.created_by = auth.uid()
      )
    );
$$;

revoke all on function public._can_edit_audience_group(uuid) from public;

-- Admins see every group. A host sees the groups they created.
create or replace function public.list_audience_groups()
returns jsonb
language plpgsql
stable
security definer
set search_path to public
as $$
declare
  _is_admin boolean;
begin
  if not public._caller_is_host_or_admin() then
    return '[]'::jsonb;
  end if;

  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and role = 'admin'
  ) into _is_admin;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'id', g.id,
        'name', g.name,
        'member_count', (
          select count(*) from public.audience_group_members m
          where m.group_id = g.id
        ),
        'created_by', g.created_by
      ) order by g.name)
      from public.audience_groups g
      where _is_admin or g.created_by = auth.uid()
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.list_audience_groups() from public;
grant execute on function public.list_audience_groups() to authenticated;

create or replace function public.create_audience_group(_name text)
returns jsonb
language plpgsql
security definer
set search_path to public
as $$
declare
  _id uuid;
  _clean text := btrim(coalesce(_name, ''));
begin
  if not public._caller_is_host_or_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if _clean = '' then
    return jsonb_build_object('status', 'empty_name');
  end if;

  insert into public.audience_groups (name, created_by)
  values (_clean, auth.uid())
  returning id into _id;

  return jsonb_build_object('status', 'ok', 'id', _id, 'name', _clean);
end;
$$;

revoke all on function public.create_audience_group(text) from public;
grant execute on function public.create_audience_group(text) to authenticated;

create or replace function public.delete_audience_group(_group_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to public
as $$
begin
  if not exists (select 1 from public.audience_groups where id = _group_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public._can_edit_audience_group(_group_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  delete from public.audience_groups where id = _group_id;
  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.delete_audience_group(uuid) from public;
grant execute on function public.delete_audience_group(uuid) to authenticated;

create or replace function public.list_audience_group_members(_group_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to public
as $$
begin
  if not public._can_edit_audience_group(_group_id) then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'user_id', p.id,
        'full_name', coalesce(nullif(btrim(p.full_name), ''), p.email, ''),
        'email', p.email
      ) order by p.full_name)
      from public.audience_group_members m
      join public.profiles p on p.id = m.user_id
      where m.group_id = _group_id
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.list_audience_group_members(uuid) from public;
grant execute on function public.list_audience_group_members(uuid) to authenticated;

-- Email autocomplete. Any account with an email, not only hosts: the point
-- of the group is the students who should see the event.
create or replace function public.search_people_by_email(_query text)
returns jsonb
language plpgsql
stable
security definer
set search_path to public
as $$
declare
  _term text;
begin
  if not public._caller_is_host_or_admin() then
    return '[]'::jsonb;
  end if;

  _term := btrim(coalesce(_query, ''));
  if length(_term) < 2 then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'user_id', p.id,
        'full_name', coalesce(nullif(btrim(p.full_name), ''), p.email, ''),
        'email', p.email
      ) order by p.email)
      from (
        select p.id, p.full_name, p.email
        from public.profiles p
        where p.deleted_at is null
          and p.banned_at is null
          and p.email is not null
          and (
            p.email ilike '%' || _term || '%'
            or coalesce(p.full_name, '') ilike '%' || _term || '%'
          )
        order by p.email
        limit 8
      ) p
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.search_people_by_email(text) from public;
grant execute on function public.search_people_by_email(text) to authenticated;

create or replace function public.add_audience_group_member(
  _group_id uuid,
  _user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to public
as $$
begin
  if not exists (select 1 from public.audience_groups where id = _group_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public._can_edit_audience_group(_group_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if not exists (
    select 1 from public.profiles
    where id = _user_id and deleted_at is null
  ) then
    return jsonb_build_object('status', 'not_found');
  end if;

  insert into public.audience_group_members (group_id, user_id, added_by)
  values (_group_id, _user_id, auth.uid())
  on conflict (group_id, user_id) do nothing;

  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.add_audience_group_member(uuid, uuid) from public;
grant execute on function public.add_audience_group_member(uuid, uuid) to authenticated;

create or replace function public.remove_audience_group_member(
  _group_id uuid,
  _user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to public
as $$
begin
  if not public._can_edit_audience_group(_group_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  delete from public.audience_group_members
  where group_id = _group_id and user_id = _user_id;

  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.remove_audience_group_member(uuid, uuid) from public;
grant execute on function public.remove_audience_group_member(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Visibility. 0084's body, plus specific_groups: a student sees the event
-- when they belong to one of the groups attached to it. Managers still
-- see it through can_manage_event, above this case.
-- ---------------------------------------------------------------------------
create or replace function public.event_is_visible_to(
  _event_id uuid,
  _user_id  uuid default auth.uid()
)
returns boolean
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  _visibility      text;
  _has_faculty     boolean;
  _has_degree      boolean;
  _faculty_ok      boolean;
  _degree_ok       boolean;
begin
  select e.visibility into _visibility
  from public.events e
  where e.id = _event_id;

  if not found then
    return true;
  end if;

  if _user_id is not null and public.can_manage_event(_event_id, _user_id) then
    return true;
  end if;

  case coalesce(_visibility, 'everyone')

    when 'only_me' then
      return false;

    when 'specific_groups' then
      if _user_id is null then
        return false;
      end if;

      return exists (
        select 1
        from public.event_visibility_targets t
        join public.audience_group_members m
          on m.group_id::text = t.target_value
        where t.event_id = _event_id
          and t.target_type = 'audience_group'
          and m.user_id = _user_id
      );

    when 'specific_faculties' then
      if _user_id is null then
        return false;
      end if;

      select
        exists (
          select 1 from public.event_visibility_targets t
          where t.event_id = _event_id and t.target_type = 'faculty'
        ),
        exists (
          select 1 from public.event_visibility_targets t
          where t.event_id = _event_id and t.target_type = 'degree'
        )
      into _has_faculty, _has_degree;

      if not _has_faculty and not _has_degree then
        return true;
      end if;

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

      return _faculty_ok and _degree_ok;

    else
      return true;

  end case;

  return true;
end;
$$;

revoke all on function public.event_is_visible_to(uuid, uuid) from public;
grant execute on function public.event_is_visible_to(uuid, uuid) to authenticated, anon;

-- Publishing a specific-groups event notifies the people in those groups,
-- not the whole campus. 20261112's body, plus that filter.
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
      )
      and (
        coalesce(_event.visibility, 'everyone') <> 'specific_groups'
        or exists (
          select 1
          from public.event_visibility_targets t
          join public.audience_group_members m
            on m.group_id::text = t.target_value
          where t.event_id = _event.id
            and t.target_type = 'audience_group'
            and m.user_id = p.id
        )
      );
  exception when others then
    raise warning 'event_published fan-out failed for event % (%): %',
      new.id, sqlstate, sqlerrm;
  end;

  return new;
end;
$$;

-- An edit that leaves specific_groups must not treat the whole campus as
-- already notified. Membership is checked against the snapshot taken at
-- the start of the transaction when one exists, otherwise the live rows.
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

  _use_snapshot :=
    to_regclass('pg_temp.event_audience_snapshotted') is not null
    and exists (
      select 1 from pg_temp.event_audience_snapshotted where event_id = _event_id
    );

  if coalesce(_visibility, 'everyone') = 'specific_groups' then
    if _use_snapshot then
      return exists (
        select 1
        from pg_temp.event_audience_before t
        join public.audience_group_members m
          on m.group_id::text = t.target_value
        where t.event_id = _event_id
          and t.target_type = 'audience_group'
          and m.user_id = _user_id
      );
    end if;

    return exists (
      select 1
      from public.event_visibility_targets t
      join public.audience_group_members m
        on m.group_id::text = t.target_value
      where t.event_id = _event_id
        and t.target_type = 'audience_group'
        and m.user_id = _user_id
    );
  end if;

  if coalesce(_visibility, 'everyone') <> 'specific_faculties' then
    return true;
  end if;

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
