-- Students should be able to walk up to an event, scan its QR code, and be
-- checked in on the spot even if they never pre-registered — pre-registration
-- stays available (for planning/capacity), but scanning the event's own QR
-- is now itself a valid way to join. Previously `scan_event_attendance`
-- rejected the scan with 'not_registered' unless a prior `register_for_event`
-- call had happened.
create or replace function public.scan_event_attendance(_token uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  _token_row public.event_qr_tokens%rowtype;
  _event public.events%rowtype;
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
