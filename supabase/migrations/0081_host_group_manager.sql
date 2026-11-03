-- Host Group Manager (מנהל קבוצת מארחים): a delegated-admin tier that owns a
-- set of hosts.
--
-- RUN 0080 FIRST, AS ITS OWN BATCH. This file casts to the
-- `host_group_manager` enum value, which Postgres refuses to let a
-- transaction use in the same statement batch that created it.
--
-- What the role can do, and nothing beyond it:
--   * See and approve events authored by hosts assigned to it. An approval
--     publishes outright — no second pass by an app admin.
--   * Create its own events, which publish without approval.
--   * Confirm attendance manually for its own events and its hosts' events.
--   * Create new accounts, host-only, which join its group automatically.
--
-- What it explicitly cannot do:
--   * Touch a host, event or attendance outside its own group.
--   * Assign or reassign hosts — only an app admin does that.
--   * Create a student, an admin, or another group manager.
--   * Change any existing user's roles.
--
-- Design notes worth knowing before reading:
--
--   * `can_manage_event` (0062) is NOT widened to include group managers. It
--     backs the UPDATE and DELETE policies on `events`, so widening it would
--     silently hand managers edit and delete rights over their hosts' events —
--     which the spec does not grant. Every new capability below gets its own
--     narrower predicate instead.
--   * `approve_event` is not redefined here. Like `create_event_or_program`,
--     its current body exists only in the live database, so this file adds a
--     separate `group_manager_approve_event` rather than risk reverting it.
--   * Nothing existing is deleted or rewritten except
--     `auto_approve_admin_events`, whose whole body is four lines and is
--     reproduced from 0013 with one branch added.
--
-- Depends on: 0080 (enum value), 0003 (`is_admin`), 0062 (`can_manage_event`).

-- ---------------------------------------------------------------------------
-- 1. Who manages whom
-- ---------------------------------------------------------------------------
-- `unique (host_id)` because a host belongs to at most one group at a time;
-- reassigning moves them rather than adding a second owner. That is what makes
-- "the hosts assigned to me" a well-defined set with no overlap to arbitrate.
create table if not exists public.host_group_members (
  id          uuid primary key default gen_random_uuid(),
  manager_id  uuid not null references public.profiles(id) on delete cascade,
  host_id     uuid not null references public.profiles(id) on delete cascade,
  assigned_by uuid references auth.users(id) on delete set null,
  assigned_at timestamptz not null default now(),
  unique (host_id),
  -- A manager managing themselves would make `manages_host` reflexive and let
  -- a manager approve their own events twice over. They already publish
  -- without approval; this keeps the two paths from overlapping.
  constraint host_group_members_no_self check (manager_id <> host_id)
);

create index if not exists host_group_members_manager_idx
  on public.host_group_members (manager_id);

-- Separate from the assignment above, and never updated by it. The spec
-- requires the original creator to survive the host being reassigned to
-- someone else, so "who created this account" and "who manages it now" are two
-- different facts stored in two different places.
create table if not exists public.host_group_created_users (
  host_id    uuid primary key references public.profiles(id) on delete cascade,
  -- Nullable on purpose: if the manager's account is later removed, the
  -- record that the host was manager-created must outlive them.
  manager_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists host_group_created_users_manager_idx
  on public.host_group_created_users (manager_id);

grant select on public.host_group_members      to authenticated;
grant select on public.host_group_created_users to authenticated;

alter table public.host_group_members       enable row level security;
alter table public.host_group_created_users enable row level security;

-- Writes go only through the security-definer RPCs below, so no insert,
-- update or delete grant is issued to `authenticated` for either table.

drop policy if exists host_group_members_select on public.host_group_members;
create policy host_group_members_select
  on public.host_group_members
  for select
  to authenticated
  using (
    public.is_admin()
    or manager_id = auth.uid()   -- my group
    or host_id    = auth.uid()   -- who manages me
  );

drop policy if exists host_group_created_users_select on public.host_group_created_users;
create policy host_group_created_users_select
  on public.host_group_created_users
  for select
  to authenticated
  using (public.is_admin() or manager_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 2. Predicates
-- ---------------------------------------------------------------------------
create or replace function public.is_host_group_manager(
  _user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists (
    select 1 from public.user_roles r
    where r.user_id = _user_id
      and r.role = 'host_group_manager'::app_role
  );
$$;

revoke all on function public.is_host_group_manager(uuid) from public;
grant execute on function public.is_host_group_manager(uuid) to authenticated;

-- Is _host_id in _manager_id's group? False when the caller isn't actually a
-- manager, so holding an assignment row without the role grants nothing.
create or replace function public.manages_host(
  _host_id    uuid,
  _manager_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    _manager_id is not null
    and public.is_host_group_manager(_manager_id)
    and exists (
      select 1 from public.host_group_members m
      where m.manager_id = _manager_id
        and m.host_id    = _host_id
    );
$$;

revoke all on function public.manages_host(uuid, uuid) from public;
grant execute on function public.manages_host(uuid, uuid) to authenticated;

-- May this group manager act on this event? True for events they authored and
-- for events authored by a host in their group.
--
-- Deliberately narrower than `can_manage_event`: this authorizes viewing,
-- approving and confirming attendance, not editing or deleting.
create or replace function public.group_manager_can_act_on_event(
  _event_id uuid,
  _user_id  uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    _user_id is not null
    and public.is_host_group_manager(_user_id)
    and exists (
      select 1 from public.events e
      where e.id = _event_id
        and (
          e.created_by = _user_id
          or public.manages_host(e.created_by, _user_id)
        )
    );
$$;

revoke all on function public.group_manager_can_act_on_event(uuid, uuid) from public;
grant execute on function public.group_manager_can_act_on_event(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. A group manager's own events publish without approval
-- ---------------------------------------------------------------------------
-- 0013's body verbatim, plus the group-manager branch. Still keyed on
-- `created_by` rather than `auth.uid()`, so the rule follows the author.
create or replace function public.auto_approve_admin_events()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_admin(new.created_by)
     or public.is_host_group_manager(new.created_by)
  then
    new.approval_status := 'approved';
    new.rejection_reason := null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_auto_approve_admin_events on public.events;
create trigger trg_auto_approve_admin_events
  before insert on public.events
  for each row
  execute function public.auto_approve_admin_events();

-- ---------------------------------------------------------------------------
-- 4. Reading the group
-- ---------------------------------------------------------------------------
-- The hosts in my group.
create or replace function public.list_my_group_hosts()
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
begin
  if not public.is_host_group_manager() then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'user_id',     p.id,
        'full_name',   coalesce(nullif(btrim(p.full_name), ''), p.email, ''),
        'email',       p.email,
        'student_id',  p.student_id,
        'assigned_at', m.assigned_at,
        -- Whether this manager is also the account's original creator.
        'created_by_me', exists (
          select 1 from public.host_group_created_users c
          where c.host_id = p.id and c.manager_id = auth.uid()
        )
      ) order by coalesce(nullif(btrim(p.full_name), ''), p.email))
      from public.host_group_members m
      join public.profiles p on p.id = m.host_id
      where m.manager_id = auth.uid()
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.list_my_group_hosts() from public;
grant execute on function public.list_my_group_hosts() to authenticated;

-- Events I may act on: mine, plus those authored by my hosts. Any status —
-- the pending ones are the point, since approving them is the job.
--
-- `security definer` because a manager has no SELECT path to a host's
-- `pending` event through the public policies.
create or replace function public.list_my_group_events()
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
begin
  if not public.is_host_group_manager() then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(to_jsonb(e) || jsonb_build_object(
        'author_name',
          coalesce(nullif(btrim(p.full_name), ''), p.email, ''),
        'is_mine', e.created_by = auth.uid()
      ) order by e.starts_at desc)
      from public.events e
      left join public.profiles p on p.id = e.created_by
      where e.created_by = auth.uid()
         or public.manages_host(e.created_by, auth.uid())
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.list_my_group_events() from public;
grant execute on function public.list_my_group_events() to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Approving as a group manager
-- ---------------------------------------------------------------------------
-- Publishes outright. The spec is explicit that no further admin pass is
-- required, so this sets `approved` rather than handing off to a queue.
--
-- A manager approving their *own* event is a no-op in practice — section 3
-- already published it on insert — but is allowed rather than refused, so a
-- legacy pending event authored before this migration can still be cleared.
create or replace function public.group_manager_approve_event(
  _event_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not exists (select 1 from public.events where id = _event_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public.group_manager_can_act_on_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  update public.events
     set approval_status  = 'approved',
         rejection_reason = null
   where id = _event_id;

  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.group_manager_approve_event(uuid) from public;
grant execute on function public.group_manager_approve_event(uuid) to authenticated;

create or replace function public.group_manager_reject_event(
  _event_id uuid,
  _reason   text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not exists (select 1 from public.events where id = _event_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public.group_manager_can_act_on_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  update public.events
     set approval_status  = 'rejected',
         rejection_reason = nullif(btrim(coalesce(_reason, '')), '')
   where id = _event_id;

  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.group_manager_reject_event(uuid, text) from public;
grant execute on function public.group_manager_reject_event(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. Manual attendance for the group
-- ---------------------------------------------------------------------------
-- 0062's body, with the authorization line widened by one disjunct. Everything
-- else — eligibility, registration, duplicate-scan and point-award behaviour —
-- is unchanged.
create or replace function public.confirm_attendance_by_student_id(_event_id uuid, _student_id text, _session_id uuid default null::uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id  uuid;
  v_event    public.events%rowtype;
  v_points   int;
  v_title    text;
begin
  select * into v_event from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'invalid', 'points', 0);
  end if;
  v_title := v_event.title;

  -- Widened in 0081: a group manager may confirm attendance for their own
  -- events and their hosts'. `can_manage_event` is left alone so this does not
  -- also grant edit/delete through the RLS policies that use it.
  if not (
    public.can_manage_event(_event_id)
    or public.group_manager_can_act_on_event(_event_id)
  ) then
    return jsonb_build_object('status', 'invalid', 'points', 0, 'event_title', v_title);
  end if;

  select id into v_user_id
  from public.profiles
  where student_id = regexp_replace(coalesce(_student_id, ''), '\s', '', 'g');

  if v_user_id is null then
    return jsonb_build_object('status', 'invalid', 'points', 0, 'event_title', v_title);
  end if;

  if not public.is_student_eligible(v_user_id) then
    return jsonb_build_object('status', 'not_a_student', 'points', 0, 'event_title', v_title);
  end if;

  if not exists (
    select 1 from public.event_registrations
    where event_id = _event_id and user_id = v_user_id
  ) then
    return jsonb_build_object('status', 'not_registered', 'points', 0, 'event_title', v_title);
  end if;

  if exists (
    select 1 from public.event_attendance
    where event_id = _event_id
      and user_id  = v_user_id
      and (_session_id is null or session_id = _session_id)
  ) then
    return jsonb_build_object('status', 'already_scanned', 'points', 0, 'event_title', v_title);
  end if;

  v_points := coalesce(v_event.points, 0);

  insert into public.event_attendance (event_id, user_id, session_id)
  values (_event_id, v_user_id, _session_id);

  if v_points > 0 then
    insert into public.point_transactions (user_id, amount, reason, metadata)
    values (
      v_user_id,
      v_points,
      'event_attendance',
      jsonb_build_object(
        'event_id',     _event_id,
        'session_id',   _session_id,
        'event_title',  v_title,
        'confirmed_by', auth.uid(),
        'method',       'student_id'
      )
    );
  end if;

  return jsonb_build_object('status', 'ok', 'points', v_points, 'event_title', v_title);
end;
$$;

-- Registrant lists for the group, so a manager can see who signed up for an
-- event they are being asked to approve. Mirrors
-- `admin_list_event_registrants` (0031/0062) but gated on the group predicate.
create or replace function public.group_manager_list_event_registrants(
  _event_id   uuid,
  _session_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
begin
  if not public.group_manager_can_act_on_event(_event_id) then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'user_id',       p.id,
        'full_name',     p.full_name,
        'email',         p.email,
        'gender',        p.gender,
        'faculty',       coalesce((p.faculties)[1], p.faculty),
        'field_of_study',coalesce((p.fields_of_study)[1], p.field_of_study),
        'interests',     coalesce(p.interests, '{}'::text[]),
        'registered_at', r.registered_at,
        'attended_at',   a.scanned_at
      ) order by r.registered_at)
      from public.event_registrations r
      join public.profiles p on p.id = r.user_id
      left join public.event_attendance a
        on a.event_id = r.event_id
       and a.user_id  = r.user_id
       and a.session_id is not distinct from _session_id
      where r.event_id = _event_id
        and r.session_id is null
        and r.status = 'registered'
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.group_manager_list_event_registrants(uuid, uuid) from public;
grant execute on function public.group_manager_list_event_registrants(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 7. Admin: assigning hosts to a manager
-- ---------------------------------------------------------------------------
-- Every host, flagged with whether this manager has them and — when someone
-- else does — who. Rendering the whole list from one call, and showing the
-- conflict rather than hiding it, is what stops an admin silently stealing a
-- host from another group without realising.
create or replace function public.admin_list_group_hosts(
  _manager_id uuid
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
        'user_id',   p.id,
        'full_name', coalesce(nullif(btrim(p.full_name), ''), p.email, ''),
        'email',     p.email,
        'assigned',  m.manager_id is not distinct from _manager_id,
        'other_manager_id', case
          when m.manager_id is not null and m.manager_id <> _manager_id
          then m.manager_id else null end,
        'other_manager_name', case
          when m.manager_id is not null and m.manager_id <> _manager_id
          then coalesce(nullif(btrim(mp.full_name), ''), mp.email) else null end
      ) order by coalesce(nullif(btrim(p.full_name), ''), p.email))
      from public.profiles p
      join public.user_roles r
        on r.user_id = p.id and r.role = 'host'::app_role
      left join public.host_group_members m on m.host_id = p.id
      left join public.profiles mp on mp.id = m.manager_id
      where p.id <> _manager_id
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.admin_list_group_hosts(uuid) from public;
grant execute on function public.admin_list_group_hosts(uuid) to authenticated;

-- Replaces _manager_id's group with exactly _host_ids.
--
-- Moving a host who belongs to another manager is allowed and is what the
-- unique constraint makes atomic — the old row is replaced, not duplicated.
-- `host_group_created_users` is untouched, so the original creator survives
-- the move.
create or replace function public.admin_set_group_hosts(
  _manager_id uuid,
  _host_ids   uuid[]
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

  if not public.is_host_group_manager(_manager_id) then
    return jsonb_build_object('status', 'not_a_manager');
  end if;

  -- Drop anything this manager has that is no longer wanted.
  delete from public.host_group_members
  where manager_id = _manager_id
    and (
      _host_ids is null
      or cardinality(_host_ids) = 0
      or host_id <> all (_host_ids)
    );

  if _host_ids is not null and cardinality(_host_ids) > 0 then
    insert into public.host_group_members (manager_id, host_id, assigned_by)
    select _manager_id, ids.host_id, auth.uid()
    from (select distinct unnest(_host_ids) as host_id) as ids
    where ids.host_id <> _manager_id
      and exists (
        select 1 from public.user_roles r
        where r.user_id = ids.host_id and r.role = 'host'::app_role
      )
    -- Reassignment: the host already belongs to someone, so move them.
    on conflict (host_id) do update
      set manager_id  = excluded.manager_id,
          assigned_by = excluded.assigned_by,
          assigned_at = now();
  end if;

  select count(*) into _count
  from public.host_group_members
  where manager_id = _manager_id;

  return jsonb_build_object('status', 'ok', 'assigned', _count);
end;
$$;

revoke all on function public.admin_set_group_hosts(uuid, uuid[]) from public;
grant execute on function public.admin_set_group_hosts(uuid, uuid[]) to authenticated;

-- ---------------------------------------------------------------------------
-- 8. Admin: "משתמשים שנוספו על ידי מנהלי קבוצת מארחים"
-- ---------------------------------------------------------------------------
-- Every account created by a group manager, with its original creator — which
-- is read from `host_group_created_users` and therefore unaffected by any
-- later reassignment. `current_manager_name` is shown alongside precisely so
-- the two can be seen to differ.
create or replace function public.admin_list_manager_created_users()
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
        'user_id',      p.id,
        'full_name',    coalesce(nullif(btrim(p.full_name), ''), p.email, ''),
        'email',        p.email,
        'created_at',   c.created_at,
        'creator_id',   c.manager_id,
        'creator_name',
          coalesce(nullif(btrim(cm.full_name), ''), cm.email, ''),
        'current_manager_id', m.manager_id,
        'current_manager_name',
          coalesce(nullif(btrim(curm.full_name), ''), curm.email, ''),
        'reassigned',
          m.manager_id is not null and m.manager_id is distinct from c.manager_id
      ) order by c.created_at desc)
      from public.host_group_created_users c
      join public.profiles p on p.id = c.host_id
      left join public.profiles cm on cm.id = c.manager_id
      left join public.host_group_members m on m.host_id = c.host_id
      left join public.profiles curm on curm.id = m.manager_id
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.admin_list_manager_created_users() from public;
grant execute on function public.admin_list_manager_created_users() to authenticated;

-- ---------------------------------------------------------------------------
-- 9. Recording a manager-created host
-- ---------------------------------------------------------------------------
-- Called by the `admin-create-user` edge function with the service-role key
-- after it has created the account. Not reachable from the client: no execute
-- grant to `authenticated`, so a manager cannot forge group membership for an
-- account they did not create.
create or replace function public.record_manager_created_host(
  _host_id    uuid,
  _manager_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.is_host_group_manager(_manager_id) then
    return jsonb_build_object('status', 'not_a_manager');
  end if;

  insert into public.host_group_created_users (host_id, manager_id)
  values (_host_id, _manager_id)
  on conflict (host_id) do nothing;

  insert into public.host_group_members (manager_id, host_id, assigned_by)
  values (_manager_id, _host_id, _manager_id)
  on conflict (host_id) do update
    set manager_id  = excluded.manager_id,
        assigned_by = excluded.assigned_by,
        assigned_at = now();

  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.record_manager_created_host(uuid, uuid) from public;
-- Deliberately NOT granted to `authenticated`.

-- ---------------------------------------------------------------------------
-- 10. Sanity report
-- ---------------------------------------------------------------------------
do $$
declare
  _managers int;
  _assigned int;
begin
  select count(*) into _managers
  from public.user_roles where role = 'host_group_manager'::app_role;

  select count(*) into _assigned from public.host_group_members;

  raise notice 'Host group managers: %, host assignments: %', _managers, _assigned;

  if _managers = 0 then
    raise notice 'No accounts hold host_group_manager yet — grant it from Users in the admin panel.';
  end if;
end $$;
