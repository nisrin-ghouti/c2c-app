-- Each session of a program now has its own attendance barcode, issued from
-- the admin's sessions table. That gives every session its own on/off switch
-- (`event_sessions.qr_enabled`, written by `set_event_qr_enabled` with a
-- `_session_id`) — but `scan_event_attendance` never read it.
--
-- Since 0032 the function has checked only `events.qr_enabled`, even when the
-- scanned token carries a `session_id`. That was harmless while a program had
-- a single program-level barcode; now an admin can close scanning on one
-- session and students would still be checked in, silently. Worse, the switch
-- visibly flips in the admin UI, so it reads as working.
--
-- Everything else here is carried over verbatim from 0047 (walk-up join,
-- per-session scan-once via the sentinel-uuid coalesce, full event points per
-- attendance row). Only the scanning-closed guard changes.
create or replace function public.scan_event_attendance(_token uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  _token_row public.event_qr_tokens%rowtype;
  _event public.events%rowtype;
  _session_qr_enabled boolean;
  _already record;
  _registered record;
  _code text;
begin
  if not public.is_student_eligible(auth.uid()) then
    return jsonb_build_object('status', 'not_a_student');
  end if;

  select * into _token_row from public.event_qr_tokens where token = _token
    order by issued_at desc limit 1;
  if not found then
    return jsonb_build_object('status', 'invalid');
  end if;

  select * into _event from public.events where id = _token_row.event_id;
  if not found then
    return jsonb_build_object('status', 'invalid');
  end if;

  if not _event.qr_enabled then
    return jsonb_build_object('status', 'scanning_closed');
  end if;

  -- A session-scoped token must also satisfy that session's own switch. A
  -- missing session row means the token points at something that no longer
  -- exists, which is 'invalid' rather than 'closed'.
  if _token_row.session_id is not null then
    select qr_enabled into _session_qr_enabled
      from public.event_sessions where id = _token_row.session_id;
    if not found then
      return jsonb_build_object('status', 'invalid');
    end if;
    if not coalesce(_session_qr_enabled, true) then
      return jsonb_build_object('status', 'scanning_closed');
    end if;
  end if;

  if now() > _token_row.expires_at then
    return jsonb_build_object('status', 'expired');
  end if;

  select * into _already from public.event_attendance
    where event_id = _token_row.event_id
      and coalesce(session_id, '00000000-0000-0000-0000-000000000000'::uuid)
        = coalesce(_token_row.session_id, '00000000-0000-0000-0000-000000000000'::uuid)
      and user_id = auth.uid();
  if found then
    return jsonb_build_object('status', 'already_scanned');
  end if;

  select * into _registered from public.event_registrations
    where event_id = _token_row.event_id and user_id = auth.uid();

  if not found or _registered.status <> 'registered' then
    -- Walk-up join: scanning the event's own QR is the registration step
    -- itself, so a student who never pre-registered still gets checked in
    -- instead of being turned away. No capacity check here on purpose —
    -- capacity only gates the ahead-of-time `register_for_event` path; a
    -- student physically standing at the event scanning in isn't blocked
    -- by it.
    loop
      _code := encode(gen_random_bytes(9), 'hex');
      exit when not exists (select 1 from public.event_registrations where code = _code);
    end loop;

    insert into public.event_registrations (event_id, session_id, user_id, status, registered_at, code)
    values (_token_row.event_id, _token_row.session_id, auth.uid(), 'registered', now(), _code)
    on conflict (event_id, user_id) do update
      set status = 'registered', registered_at = now(), session_id = excluded.session_id;
  end if;

  insert into public.event_attendance (event_id, session_id, user_id, points_awarded)
  values (_token_row.event_id, _token_row.session_id, auth.uid(), _event.points);

  insert into public.point_transactions (user_id, amount, reason, metadata)
  values (auth.uid(), _event.points, 'event_attendance', jsonb_build_object('event_id', _event.id, 'event_title', _event.title));

  return jsonb_build_object('status', 'ok', 'points', _event.points, 'event_title', _event.title);
end;
$$;
