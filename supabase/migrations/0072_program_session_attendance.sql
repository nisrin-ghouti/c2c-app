-- Per-session attendance for a program.
--
-- `event_attendance` has always been session-scoped — 0015 onwards insert a
-- `session_id`, and 0061 gave each session its own scanning toggle — but
-- nothing could ask "who turned up to THIS session". The closest existing call,
-- `admin_list_event_registrants(_event_id, _session_id)`, lists the event's
-- registrants and left-joins attendance for one session, which is the right
-- idea but reached only from the whole-event registrant list, and it has no
-- notion of the accepted-participants list 0071 introduced.
--
-- This adds one read: the roster for a single session, each person flagged
-- attended or not, with the scan time when they did.
--
-- Which people count as the roster:
--
--   * The accepted-participants list (0071), when the program has one. That is
--     the population the spec asks for — the people actually taken onto the
--     program.
--   * Otherwise the event's registrants, which is the set the existing
--     per-session attendance join already used. A program whose accepted list
--     has not been filled in yet therefore keeps showing exactly what it shows
--     today instead of an empty modal.
--
-- The answer says which of the two it used (`population`), so the UI can label
-- the list honestly rather than implying one and showing the other.
--
-- Read-only: scanning, point awards and `confirm_attendance_by_student_id` are
-- untouched.
--
-- Depends on 0071 for `program_accepted_participants`.

create or replace function public.admin_list_session_attendance(
  _event_id   uuid,
  _session_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  _use_accepted boolean;
  _rows         jsonb;
begin
  if not exists (select 1 from public.events where id = _event_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public.can_manage_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  -- Guard against a session id from another event being passed in, which would
  -- otherwise silently report everyone as absent.
  if _session_id is not null and not exists (
    select 1 from public.event_sessions
    where id = _session_id and event_id = _event_id
  ) then
    return jsonb_build_object('status', 'not_found');
  end if;

  select exists (
    select 1 from public.program_accepted_participants
    where event_id = _event_id
  ) into _use_accepted;

  select coalesce(jsonb_agg(entry order by entry->>'full_name'), '[]'::jsonb)
    into _rows
  from (
    select jsonb_build_object(
             'user_id',     roster.user_id,
             'full_name',   coalesce(nullif(btrim(p.full_name), ''), p.email, ''),
             'email',       p.email,
             'student_id',  p.student_id,
             'gender',      p.gender,
             'faculty',     coalesce((p.faculties)[1], p.faculty),
             'field_of_study', coalesce((p.fields_of_study)[1], p.field_of_study),
             'interests',   coalesce(p.interests, '{}'::text[]),
             'joined_at',   roster.joined_at,
             'attended_at', att.scanned_at,
             'attended',    att.scanned_at is not null
           ) as entry
    from (
      -- The accepted list…
      select a.user_id, a.added_at as joined_at
      from public.program_accepted_participants a
      where _use_accepted
        and a.event_id = _event_id

      union all

      -- …or the registrants, when there is no accepted list. `session_id is
      -- null` matches admin_list_event_registrants: a registration is for the
      -- event as a whole, never for one session.
      select r.user_id, r.registered_at as joined_at
      from public.event_registrations r
      where not _use_accepted
        and r.event_id = _event_id
        and r.session_id is null
        and r.status = 'registered'
    ) as roster
    join public.profiles p on p.id = roster.user_id
    left join public.event_attendance att
      on att.event_id = _event_id
     and att.user_id  = roster.user_id
     -- Session-scoped on purpose: an attendance row for a different session of
     -- the same program must not mark this one attended.
     and att.session_id is not distinct from _session_id
  ) as built;

  return jsonb_build_object(
    'status',     'ok',
    'population', case when _use_accepted then 'accepted' else 'registrants' end,
    'attended',   (
      select count(*) from jsonb_array_elements(_rows) e
      where (e->>'attended')::boolean
    ),
    'total',      jsonb_array_length(_rows),
    'participants', _rows
  );
end;
$$;

revoke all on function public.admin_list_session_attendance(uuid, uuid) from public;
grant execute on function public.admin_list_session_attendance(uuid, uuid) to authenticated;
