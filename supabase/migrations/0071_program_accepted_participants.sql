-- Programs get two participant lists instead of one.
--
-- Right now a program has exactly one population: whoever holds a
-- `registered` row in `event_registrations`. That conflates two different
-- things for any program with a selection step — everyone who *applied*, and
-- the smaller set who were *taken on*. Statistics computed over the first
-- answer questions about demand; the second is who actually turns up, and
-- there was no way to record it.
--
-- This adds the second list as its own table, leaving registrations exactly as
-- they are:
--
--   * Registrants  — unchanged, `event_registrations`, written by the student.
--   * Accepted     — new, `program_accepted_participants`, written by an admin
--                    or host. Members may be picked from the registrants, or
--                    added by student ID for someone who never registered
--                    (the walk-in / offline-application case).
--
-- Duplicates are impossible rather than merely discouraged: a unique
-- constraint on (event_id, user_id) plus `on conflict do nothing` in the only
-- function that writes, so a double-submit or re-adding someone who's already
-- accepted is a silent no-op, not a second row and not an error.
--
-- Nothing is removed and no existing query changes behaviour. A program with
-- no accepted rows yet simply has an empty second list, which is what every
-- existing program will look like until someone populates it.

-- ---------------------------------------------------------------------------
-- 1. Table
-- ---------------------------------------------------------------------------
create table if not exists public.program_accepted_participants (
  id          uuid primary key default gen_random_uuid(),
  event_id    uuid not null references public.events (id)   on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  added_by    uuid references auth.users (id) on delete set null,
  added_at    timestamptz not null default now(),
  -- True when the person was taken from the registrants list, false when an
  -- admin added them by student ID. Recorded at insert time because
  -- a registration can later be cancelled, and "how did this person get here"
  -- shouldn't change retroactively.
  from_registration boolean not null default false,
  unique (event_id, user_id)
);

create index if not exists program_accepted_participants_event_idx
  on public.program_accepted_participants (event_id);

-- SELECT only. Every write goes through the security-definer RPCs below, which
-- is what enforces "a host may only touch their own program".
grant select on public.program_accepted_participants to authenticated;

alter table public.program_accepted_participants enable row level security;

drop policy if exists program_accepted_select_managers
  on public.program_accepted_participants;
create policy program_accepted_select_managers
  on public.program_accepted_participants
  for select
  to authenticated
  using (public.can_manage_event(event_id));

-- A student may see that they themselves were accepted — needed if the app
-- ever surfaces "you're in". Deliberately narrow: their own row only.
drop policy if exists program_accepted_select_self
  on public.program_accepted_participants;
create policy program_accepted_select_self
  on public.program_accepted_participants
  for select
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 2. Read the accepted list
-- ---------------------------------------------------------------------------
-- Same row shape as `admin_list_event_registrants` so the admin console can
-- render both lists and compute both sets of statistics with one widget and
-- one entity. `registered_at` carries the accepted-at timestamp for that
-- reason — it is the "when did this person join this list" column in both
-- cases, and the UI labels it per list.
--
-- `attended_at` is the EARLIEST attendance scan anywhere in the program, which
-- is how `programRegistrantsProvider` already collapses a multi-session
-- program into one attended/not-attended answer per person. Per-session
-- attendance is a different question, answered by 0072.
create or replace function public.admin_list_program_accepted(
  _event_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
begin
  if not exists (select 1 from public.events where id = _event_id) then
    return '[]'::jsonb;
  end if;

  if not public.can_manage_event(_event_id) then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'user_id',        p.id,
        'full_name',      p.full_name,
        'email',          p.email,
        'student_id',     p.student_id,
        'gender',         p.gender,
        -- The single-value columns the admin console's registrant entity
        -- expects, taken from the multi-value arrays (0001) with the legacy
        -- scalar columns as fallback.
        'faculty',        coalesce((p.faculties)[1], p.faculty),
        'field_of_study', coalesce((p.fields_of_study)[1], p.field_of_study),
        'interests',      coalesce(p.interests, '{}'::text[]),
        'registered_at',  a.added_at,
        'accepted_at',    a.added_at,
        'from_registration', a.from_registration,
        -- Whether they currently also hold a live registration. Lets the UI
        -- flag an accepted participant whose registration was cancelled.
        'is_registrant',  exists (
          select 1 from public.event_registrations r
          where r.event_id = _event_id
            and r.user_id = p.id
            and r.status = 'registered'
        ),
        'attended_at',    (
          select min(att.scanned_at)
          from public.event_attendance att
          where att.event_id = _event_id
            and att.user_id = p.id
        ),
        'attended_sessions', (
          select count(distinct att.session_id)
          from public.event_attendance att
          where att.event_id = _event_id
            and att.user_id = p.id
            and att.session_id is not null
        )
      ) order by a.added_at)
      from public.program_accepted_participants a
      join public.profiles p on p.id = a.user_id
      where a.event_id = _event_id
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.admin_list_program_accepted(uuid) from public;
grant execute on function public.admin_list_program_accepted(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Accept people already on the registrants list
-- ---------------------------------------------------------------------------
-- Takes an array so the UI can accept a multi-select in one round trip, and so
-- the whole batch shares one transaction. Reports how many rows it actually
-- created versus how many were already there, which is what lets the UI say
-- "3 added, 2 already accepted" instead of claiming five additions.
create or replace function public.admin_add_program_accepted(
  _event_id uuid,
  _user_ids uuid[]
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _before int;
  _after  int;
  _asked  int;
begin
  if not exists (select 1 from public.events where id = _event_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public.can_manage_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if _user_ids is null or cardinality(_user_ids) = 0 then
    return jsonb_build_object('status', 'ok', 'added', 0, 'skipped', 0);
  end if;

  select count(*) into _before
  from public.program_accepted_participants
  where event_id = _event_id;

  -- `distinct` guards against the same id appearing twice in one call, which
  -- the unique constraint would otherwise turn into a failed statement rather
  -- than a skipped row.
  insert into public.program_accepted_participants
    (event_id, user_id, added_by, from_registration)
  select
    _event_id,
    ids.user_id,
    auth.uid(),
    exists (
      select 1 from public.event_registrations r
      where r.event_id = _event_id
        and r.user_id = ids.user_id
        and r.status = 'registered'
    )
  from (select distinct unnest(_user_ids) as user_id) as ids
  -- Only real profiles; a bad id is skipped, not an error for the whole batch.
  where exists (select 1 from public.profiles p where p.id = ids.user_id)
  on conflict (event_id, user_id) do nothing;

  select count(*) into _after
  from public.program_accepted_participants
  where event_id = _event_id;

  select count(distinct u) into _asked from unnest(_user_ids) as u;

  return jsonb_build_object(
    'status',  'ok',
    'added',   _after - _before,
    'skipped', _asked - (_after - _before)
  );
end;
$$;

revoke all on function public.admin_add_program_accepted(uuid, uuid[]) from public;
grant execute on function public.admin_add_program_accepted(uuid, uuid[]) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Accept someone who never registered
-- ---------------------------------------------------------------------------
-- By student ID, matching how manual attendance identifies a person
-- (`confirm_attendance_by_student_id`), including the same whitespace
-- stripping — admins read these off a card and type them with spaces.
--
-- Returns the resolved name so the UI can confirm *who* it just added rather
-- than echoing the number back.
create or replace function public.admin_add_program_accepted_by_student_id(
  _event_id   uuid,
  _student_id text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _user_id uuid;
  _name    text;
begin
  if not exists (select 1 from public.events where id = _event_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public.can_manage_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  select p.id, coalesce(nullif(btrim(p.full_name), ''), p.email)
    into _user_id, _name
  from public.profiles p
  where p.student_id = regexp_replace(coalesce(_student_id, ''), '\s', '', 'g');

  if _user_id is null then
    return jsonb_build_object('status', 'no_such_student');
  end if;

  if exists (
    select 1 from public.program_accepted_participants
    where event_id = _event_id and user_id = _user_id
  ) then
    -- Not an error: the end state the admin wanted is already true. Named
    -- distinctly so the UI can say so instead of reporting a fresh addition.
    return jsonb_build_object('status', 'already', 'full_name', _name);
  end if;

  insert into public.program_accepted_participants
    (event_id, user_id, added_by, from_registration)
  values (
    _event_id,
    _user_id,
    auth.uid(),
    exists (
      select 1 from public.event_registrations r
      where r.event_id = _event_id
        and r.user_id = _user_id
        and r.status = 'registered'
    )
  )
  on conflict (event_id, user_id) do nothing;

  return jsonb_build_object('status', 'ok', 'full_name', _name, 'user_id', _user_id);
end;
$$;

revoke all on function public.admin_add_program_accepted_by_student_id(uuid, text) from public;
grant execute on function public.admin_add_program_accepted_by_student_id(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Un-accept
-- ---------------------------------------------------------------------------
-- Removes only the acceptance. The person's registration, attendance records
-- and awarded points are untouched — being dropped from the accepted list is
-- not a reason to rewrite history about a session they attended.
create or replace function public.admin_remove_program_accepted(
  _event_id uuid,
  _user_id  uuid
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

  if not public.can_manage_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  delete from public.program_accepted_participants
  where event_id = _event_id and user_id = _user_id;

  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.admin_remove_program_accepted(uuid, uuid) from public;
grant execute on function public.admin_remove_program_accepted(uuid, uuid) to authenticated;
