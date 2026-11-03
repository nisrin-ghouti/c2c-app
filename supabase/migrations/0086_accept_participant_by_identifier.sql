-- Accept a participant onto a program by student number OR email.
--
-- `admin_add_program_accepted_by_student_id` (0071) matches only
-- `profiles.student_id`, which is the number printed on a campus card. An
-- admin working from a mailing list or a forwarded message has an email
-- address instead and no way to use it.
--
-- This adds one function that accepts either, rather than a second
-- email-only one, so the admin panel can offer a single field instead of
-- making someone choose which kind of identifier they are holding before
-- they type it.
--
-- 0071's function is left exactly as it is. It is still granted and still
-- works; nothing that calls it changes behaviour.
--
-- Matching rules, in order:
--   1. student_id, after stripping whitespace (admins read these off a card
--      and type them with spaces) — same normalisation 0071 and
--      `confirm_attendance_by_student_id` already use.
--   2. email, case-insensitively and trimmed.
--
-- student_id is tried first so a numeric string can never be mistaken for an
-- address, and the two are disjoint in practice anyway.
--
-- Duplicate protection is unchanged and still comes from the unique
-- constraint on (event_id, user_id) plus `on conflict do nothing`: finding
-- the same person by email that someone else already added by number is a
-- reported no-op, not a second row.
--
-- Depends on 0071.

create or replace function public.admin_add_program_accepted_by_identifier(
  _event_id   uuid,
  _identifier text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _cleaned  text;
  _user_id  uuid;
  _name     text;
  _matched  text;
begin
  if not exists (select 1 from public.events where id = _event_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public.can_manage_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  _cleaned := btrim(coalesce(_identifier, ''));

  if _cleaned = '' then
    return jsonb_build_object('status', 'no_such_student');
  end if;

  -- 1. Student number.
  select p.id, coalesce(nullif(btrim(p.full_name), ''), p.email)
    into _user_id, _name
  from public.profiles p
  where p.student_id = regexp_replace(_cleaned, '\s', '', 'g')
  limit 1;

  if _user_id is not null then
    _matched := 'student_id';
  else
    -- 2. Email.
    select p.id, coalesce(nullif(btrim(p.full_name), ''), p.email)
      into _user_id, _name
    from public.profiles p
    where lower(p.email) = lower(_cleaned)
    limit 1;

    if _user_id is not null then
      _matched := 'email';
    end if;
  end if;

  if _user_id is null then
    return jsonb_build_object('status', 'no_such_student');
  end if;

  if exists (
    select 1 from public.program_accepted_participants
    where event_id = _event_id and user_id = _user_id
  ) then
    return jsonb_build_object(
      'status', 'already', 'full_name', _name, 'matched_by', _matched
    );
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

  return jsonb_build_object(
    'status', 'ok', 'full_name', _name, 'user_id', _user_id,
    'matched_by', _matched
  );
end;
$$;

revoke all on function public.admin_add_program_accepted_by_identifier(uuid, text) from public;
grant execute on function public.admin_add_program_accepted_by_identifier(uuid, text) to authenticated;

-- Email lookups now have an index to match the one student_id lookups use.
-- Functional, on lower(email), because the match above is case-insensitive
-- and a plain index on `email` would not be used for it.
create index if not exists profiles_lower_email_idx
  on public.profiles (lower(email));
