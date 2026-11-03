-- Co-hosts: let the host who created an event hand the same control over it
-- to another host.
--
-- `host_event_access` has been in the schema since before these migrations
-- started, and most of the app already honours it: `EventPermissions.canManage`
-- in the mobile app, the `_can_manage` branch inside `create_event_or_program`
-- / `update_event_or_program` (0020 → 0057), and `admin_list_event_registrants`
-- (0031) all read it. What never existed anywhere is a way to *write* a row —
-- no screen grants co-host access — so in practice the table has always been
-- empty and every one of those branches was dead code.
--
-- This migration supplies the missing half: list/search/grant/revoke RPCs for
-- the admin console's Host Panel, a "my events" list that finally includes
-- events someone else created, and fixes for the two paths that still checked
-- `created_by` alone and would therefore have left a co-host half-powered.
--
-- The rules encoded below:
--   * The creator (and any admin) manages the co-host list.
--   * A co-host has full control of the event itself — edit, delete, view
--     registrants, run attendance — but not of the list. The only row they may
--     remove is their own, i.e. leaving.
--   * Only accounts that already hold `host` or `admin` can be added, so this
--     path can't be used by a host to escalate a student account's privileges.

-- ---------------------------------------------------------------------------
-- 1. Permission helpers
-- ---------------------------------------------------------------------------

-- Security definer so it can be used inside RLS policies on `events` without
-- dragging `host_event_access`'s own policies (and their `user_roles` lookups)
-- into the check — the same recursion trap 0004 untangled.
create or replace function public.has_event_host_access(
  _event_id uuid,
  _user_id  uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists (
    select 1 from public.host_event_access h
    where h.event_id = _event_id and h.host_user_id = _user_id
  );
$$;

-- The single answer to "may this user act on this event?", matching the
-- expression that 0020/0031/0057 spell out inline: admins always; hosts for
-- events they created or were granted access to.
create or replace function public.can_manage_event(
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
    public.is_admin(_user_id)
    or (
      exists (
        select 1 from public.user_roles
        where user_id = _user_id and role = 'host'
      )
      and (
        exists (
          select 1 from public.events e
          where e.id = _event_id and e.created_by = _user_id
        )
        or public.has_event_host_access(_event_id, _user_id)
      )
    );
$$;

-- Managing the co-host *list* is narrower than managing the event: creator or
-- admin only. A co-host can't add or remove anyone but themselves.
create or replace function public.can_manage_event_hosts(
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
    public.is_admin(_user_id)
    or exists (
      select 1 from public.events e
      where e.id = _event_id and e.created_by = _user_id
    );
$$;

grant execute on function public.has_event_host_access(uuid, uuid) to authenticated;
grant execute on function public.can_manage_event(uuid, uuid)      to authenticated;
grant execute on function public.can_manage_event_hosts(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. RLS — co-hosts reach the event row itself
-- ---------------------------------------------------------------------------
-- Added as separate permissive policies rather than by rewriting the existing
-- creator/admin ones: permissive policies OR together, so this widens access
-- without this migration needing to restate rules it didn't write.

drop policy if exists events_co_host_select on public.events;
create policy events_co_host_select
  on public.events
  for select
  to authenticated
  using (public.has_event_host_access(id));

drop policy if exists events_co_host_update on public.events;
create policy events_co_host_update
  on public.events
  for update
  to authenticated
  using (public.has_event_host_access(id))
  with check (public.has_event_host_access(id));

drop policy if exists events_co_host_delete on public.events;
create policy events_co_host_delete
  on public.events
  for delete
  to authenticated
  using (public.has_event_host_access(id));

-- Same for a program's sessions, which the event detail screen edits inline.
drop policy if exists event_sessions_co_host_all on public.event_sessions;
create policy event_sessions_co_host_all
  on public.event_sessions
  for all
  to authenticated
  using (public.has_event_host_access(event_id))
  with check (public.has_event_host_access(event_id));

-- ---------------------------------------------------------------------------
-- 3. "My events", now including events someone else created
-- ---------------------------------------------------------------------------
-- The admin console's Host Panel used to read `events` directly with
-- `created_by = auth.uid()`, which by definition can never return a co-hosted
-- event. Security definer so a co-hosted event that is still `pending` shows
-- up too, without depending on which select policies happen to be in place.
create or replace function public.list_my_hosted_events()
returns setof public.events
language sql
stable
security definer
set search_path to 'public'
as $$
  select e.*
  from public.events e
  where e.created_by = auth.uid()
     or public.has_event_host_access(e.id)
  order by e.starts_at desc;
$$;

grant execute on function public.list_my_hosted_events() to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Reading the co-host list
-- ---------------------------------------------------------------------------
-- Returns the creator as well, flagged `is_owner`, so the UI can render one
-- list of "who controls this event" instead of stitching two sources together.
-- Readable by anyone who can manage the event — a co-host should be able to
-- see who else is on it, even though they can't change the list.
create or replace function public.list_event_hosts(_event_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  _event public.events%rowtype;
begin
  select * into _event from public.events where id = _event_id;
  if not found or not public.can_manage_event(_event_id) then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(entry order by entry->>'is_owner' desc, entry->>'full_name')
      from (
        select jsonb_build_object(
          'user_id',    p.id,
          'full_name',  p.full_name,
          'email',      p.email,
          'avatar_url', p.avatar_url,
          'is_owner',   true
        ) as entry
        from public.profiles p
        where p.id = _event.created_by

        union all

        select jsonb_build_object(
          'user_id',    p.id,
          'full_name',  p.full_name,
          'email',      p.email,
          'avatar_url', p.avatar_url,
          'is_owner',   false
        )
        from public.host_event_access h
        join public.profiles p on p.id = h.host_user_id
        where h.event_id = _event_id
          and h.host_user_id is distinct from _event.created_by
      ) roster
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.list_event_hosts(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Searching for someone to add
-- ---------------------------------------------------------------------------
-- Deliberately not a plain `profiles` search: a host has no business listing
-- the whole user table, so this only ever returns accounts that already hold
-- `host` or `admin`, and only to someone who manages this event's list.
create or replace function public.search_host_candidates(
  _event_id uuid,
  _query    text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  _event public.events%rowtype;
  _term  text := '%' || trim(coalesce(_query, '')) || '%';
begin
  select * into _event from public.events where id = _event_id;
  if not found or not public.can_manage_event_hosts(_event_id) then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'user_id',    p.id,
          'full_name',  p.full_name,
          'email',      p.email,
          'avatar_url', p.avatar_url,
          'is_owner',   false
        )
        order by p.full_name
      )
      from (
        select p.*
        from public.profiles p
        where exists (
                select 1 from public.user_roles r
                where r.user_id = p.id and r.role in ('host', 'admin')
              )
          and p.id is distinct from _event.created_by
          and not exists (
                select 1 from public.host_event_access h
                where h.event_id = _event_id and h.host_user_id = p.id
              )
          and p.banned_at is null
          and (
            coalesce(p.full_name, '') ilike _term
            or coalesce(p.email, '') ilike _term
          )
        order by p.full_name
        limit 20
      ) p
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.search_host_candidates(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. Granting and revoking
-- ---------------------------------------------------------------------------
create or replace function public.grant_event_host_access(
  _event_id uuid,
  _user_id  uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _event public.events%rowtype;
begin
  select * into _event from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public.can_manage_event_hosts(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if _user_id = _event.created_by then
    return jsonb_build_object('status', 'is_owner');
  end if;

  -- The one privilege boundary that matters here: co-hosting is a grant of
  -- event control to someone who can already sign into a host surface, never a
  -- back door to making a student account a host.
  if not exists (
    select 1 from public.user_roles
    where user_id = _user_id and role in ('host', 'admin')
  ) then
    return jsonb_build_object('status', 'not_a_host');
  end if;

  if public.has_event_host_access(_event_id, _user_id) then
    return jsonb_build_object('status', 'already_host');
  end if;

  insert into public.host_event_access (event_id, host_user_id, granted_by)
  values (_event_id, _user_id, auth.uid());

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.grant_event_host_access(uuid, uuid) to authenticated;

-- Creator/admin may remove anyone; a co-host may remove only themselves, which
-- is how "leave this event" is expressed.
create or replace function public.revoke_event_host_access(
  _event_id uuid,
  _user_id  uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _event public.events%rowtype;
begin
  select * into _event from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  if _user_id = _event.created_by then
    return jsonb_build_object('status', 'is_owner');
  end if;

  if not (
    public.can_manage_event_hosts(_event_id)
    or _user_id = auth.uid()
  ) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  delete from public.host_event_access
  where event_id = _event_id and host_user_id = _user_id;

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.revoke_event_host_access(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 7. Manual attendance — the last creator-only check
-- ---------------------------------------------------------------------------
-- Carried over verbatim from 0033 except for the guard, which was
-- `v_event.created_by <> auth.uid()` and so silently returned 'invalid' for a
-- co-host confirming a student by ID — indistinguishable, in the UI, from a
-- wrong student number.
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

  if not public.can_manage_event(_event_id) then
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

-- ---------------------------------------------------------------------------
-- 8. Report any remaining creator-only guard
-- ---------------------------------------------------------------------------
-- `start_event_qr`, `set_event_qr_enabled` and `get_event_stats` predate this
-- migration series and live only in the live database, so this file can't
-- safely rewrite them. Instead: name any function whose body still compares
-- `created_by` to `auth.uid()` without also consulting `host_event_access`.
-- Each one printed here is a place a co-host will be turned away from.
do $$
declare
  _fn record;
  _found boolean := false;
begin
  for _fn in
    select p.oid::regprocedure as sig, pg_get_functiondef(p.oid) as def
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
  loop
    if _fn.def like '%created_by%auth.uid()%'
       and _fn.def not like '%host_event_access%'
       and _fn.def not like '%can_manage_event%' then
      raise notice 'co-host gap: % still gates on created_by alone', _fn.sig;
      _found := true;
    end if;
  end loop;

  if not _found then
    raise notice 'co-host check: no creator-only event guards left';
  end if;
end;
$$;
