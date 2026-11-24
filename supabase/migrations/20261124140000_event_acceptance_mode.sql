-- The creator of an event or a program chooses how students get in.
--
--   * auto     — registering is enough. What every one-time event does today.
--   * approval — registering only applies. A host or admin accepts people,
--                the same registrants / accepted lists a program already has.
--
-- Existing rows keep today's behaviour: programs are approval, everything
-- else is auto. Omitting the field on create does the same, so an older
-- client that does not send it cannot accidentally flip a program to auto
-- or a one-time event to a waiting list.

alter table public.events
  add column if not exists acceptance_mode text;

update public.events
set acceptance_mode = case
  when event_kind = 'program' then 'approval'
  else 'auto'
end
where acceptance_mode is null;

alter table public.events
  alter column acceptance_mode set default 'auto';

alter table public.events
  alter column acceptance_mode set not null;

alter table public.events
  drop constraint if exists events_acceptance_mode_check;

alter table public.events
  add constraint events_acceptance_mode_check
  check (acceptance_mode in ('auto', 'approval'));

-- ---------------------------------------------------------------------------
-- create / update persist the choice.
-- Bodies match 0091, plus acceptance_mode.
-- ---------------------------------------------------------------------------
create or replace function public.create_event_or_program(_event jsonb, _sessions jsonb default null::jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  _new_id uuid;
  _can_create boolean;
  _mode text;
begin
  select exists(
    select 1 from public.user_roles where user_id = auth.uid() and role in ('host','admin')
  ) into _can_create;

  if not _can_create then
    return jsonb_build_object('status', 'forbidden');
  end if;

  _mode := case
    when _event->>'acceptance_mode' in ('auto', 'approval') then _event->>'acceptance_mode'
    when coalesce(_event->>'event_kind', 'single') = 'program' then 'approval'
    else 'auto'
  end;

  insert into public.events (
    title, description, category, location, starts_at, ends_at, points,
    image_url, organizer_name, organizer_description, external_link,
    created_by, event_kind, approval_status, visibility, capacity,
    acceptance_mode,
    title_ar, title_he, description_ar, description_he,
    location_ar, location_he, organizer_name_ar, organizer_name_he,
    organizer_description_ar, organizer_description_he,
    title_en, description_en, location_en, organizer_name_en, organizer_description_en
  ) values (
    _event->>'title',
    nullif(_event->>'description', ''),
    nullif(_event->>'category', ''),
    nullif(_event->>'location', ''),
    (_event->>'starts_at')::timestamptz,
    (_event->>'ends_at')::timestamptz,
    coalesce((_event->>'points')::int, 20),
    nullif(_event->>'image_url', ''),
    nullif(_event->>'organizer_name', ''),
    nullif(_event->>'organizer_description', ''),
    nullif(_event->>'external_link', ''),
    auth.uid(),
    coalesce(_event->>'event_kind', 'single'),
    'pending',
    coalesce(_event->>'visibility', 'everyone'),
    nullif(_event->>'capacity', '')::int,
    _mode,
    nullif(_event->>'title_ar', ''),
    nullif(_event->>'title_he', ''),
    nullif(_event->>'description_ar', ''),
    nullif(_event->>'description_he', ''),
    nullif(_event->>'location_ar', ''),
    nullif(_event->>'location_he', ''),
    nullif(_event->>'organizer_name_ar', ''),
    nullif(_event->>'organizer_name_he', ''),
    nullif(_event->>'organizer_description_ar', ''),
    nullif(_event->>'organizer_description_he', ''),
    nullif(_event->>'title_en', ''),
    nullif(_event->>'description_en', ''),
    nullif(_event->>'location_en', ''),
    nullif(_event->>'organizer_name_en', ''),
    nullif(_event->>'organizer_description_en', '')
  )
  returning id into _new_id;

  if _event ? 'visibility_targets' then
    insert into public.event_visibility_targets (event_id, target_type, target_value)
    select _new_id, t->>'target_type', t->>'target_value'
    from jsonb_array_elements(_event->'visibility_targets') as t;
  end if;

  if _sessions is not null then
    insert into public.event_sessions (
      event_id, title, starts_at, ends_at, location,
      title_en, title_he, title_ar,
      location_en, location_he, location_ar
    )
    select
      _new_id,
      s->>'title',
      (s->>'starts_at')::timestamptz,
      (s->>'ends_at')::timestamptz,
      nullif(s->>'location', ''),
      nullif(s->>'title_en', ''),
      nullif(s->>'title_he', ''),
      nullif(s->>'title_ar', ''),
      nullif(s->>'location_en', ''),
      nullif(s->>'location_he', ''),
      nullif(s->>'location_ar', '')
    from jsonb_array_elements(_sessions) as s;
  end if;

  return jsonb_build_object('status', 'ok', 'id', _new_id);
end;
$function$;

create or replace function public.update_event_or_program(_event_id uuid, _event jsonb, _sessions jsonb default null::jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  _row public.events%rowtype;
  _is_admin boolean;
  _is_group_manager boolean;
  _can_manage boolean;
  _new_mode text;
begin
  select * into _row from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  select exists(select 1 from public.user_roles where user_id = auth.uid() and role = 'admin')
  into _is_admin;

  _is_group_manager := public.group_manager_can_act_on_event(_event_id);

  select
    _is_admin
    or _is_group_manager
    or (
      exists(select 1 from public.user_roles where user_id = auth.uid() and role = 'host')
      and (
        _row.created_by = auth.uid()
        or exists(select 1 from public.host_event_access h where h.event_id = _event_id and h.host_user_id = auth.uid())
      )
    )
  into _can_manage;

  if not _can_manage then
    return jsonb_build_object('status', 'forbidden');
  end if;

  _new_mode := case
    when _event->>'acceptance_mode' in ('auto', 'approval') then _event->>'acceptance_mode'
    else _row.acceptance_mode
  end;

  update public.events set
    title = coalesce(_event->>'title', title),
    description = nullif(_event->>'description', ''),
    category = nullif(_event->>'category', ''),
    location = nullif(_event->>'location', ''),
    starts_at = coalesce((_event->>'starts_at')::timestamptz, starts_at),
    ends_at = coalesce((_event->>'ends_at')::timestamptz, ends_at),
    points = coalesce((_event->>'points')::int, points),
    image_url = nullif(_event->>'image_url', ''),
    organizer_name = nullif(_event->>'organizer_name', ''),
    organizer_description = nullif(_event->>'organizer_description', ''),
    external_link = nullif(_event->>'external_link', ''),
    visibility = coalesce(_event->>'visibility', visibility),
    capacity = nullif(_event->>'capacity', '')::int,
    acceptance_mode = _new_mode,
    title_ar = nullif(_event->>'title_ar', ''),
    title_he = nullif(_event->>'title_he', ''),
    description_ar = nullif(_event->>'description_ar', ''),
    description_he = nullif(_event->>'description_he', ''),
    location_ar = nullif(_event->>'location_ar', ''),
    location_he = nullif(_event->>'location_he', ''),
    organizer_name_ar = nullif(_event->>'organizer_name_ar', ''),
    organizer_name_he = nullif(_event->>'organizer_name_he', ''),
    organizer_description_ar = nullif(_event->>'organizer_description_ar', ''),
    organizer_description_he = nullif(_event->>'organizer_description_he', ''),
    title_en = nullif(_event->>'title_en', ''),
    description_en = nullif(_event->>'description_en', ''),
    location_en = nullif(_event->>'location_en', ''),
    organizer_name_en = nullif(_event->>'organizer_name_en', ''),
    organizer_description_en = nullif(_event->>'organizer_description_en', ''),
    approval_status = case
      when _is_admin or _is_group_manager then approval_status
      when approval_status = 'approved' then 'pending'
      else approval_status
    end,
    rejection_reason = case
      when _is_admin or _is_group_manager then rejection_reason
      when approval_status = 'approved' then null
      else rejection_reason
    end
  where id = _event_id;

  -- Auto means everyone who has registered is in. Also, turning approval
  -- off-to-on must not kick out people who already got in under auto:
  -- they are accepted as part of the switch, and only later registrants wait.
  if _new_mode = 'auto'
     or (coalesce(_row.acceptance_mode, 'auto') = 'auto' and _new_mode = 'approval') then
    insert into public.program_accepted_participants
      (event_id, user_id, added_by, from_registration)
    select _event_id, r.user_id, auth.uid(), true
    from public.event_registrations r
    where r.event_id = _event_id
      and r.status = 'registered'
    on conflict (event_id, user_id) do nothing;
  end if;

  delete from public.event_visibility_targets where event_id = _event_id;
  if _event ? 'visibility_targets' then
    insert into public.event_visibility_targets (event_id, target_type, target_value)
    select _event_id, t->>'target_type', t->>'target_value'
    from jsonb_array_elements(_event->'visibility_targets') as t;
  end if;

  if _sessions is not null then
    delete from public.event_sessions where event_id = _event_id;
    insert into public.event_sessions (
      event_id, title, starts_at, ends_at, location,
      title_en, title_he, title_ar,
      location_en, location_he, location_ar
    )
    select
      _event_id,
      s->>'title',
      (s->>'starts_at')::timestamptz,
      (s->>'ends_at')::timestamptz,
      nullif(s->>'location', ''),
      nullif(s->>'title_en', ''),
      nullif(s->>'title_he', ''),
      nullif(s->>'title_ar', ''),
      nullif(s->>'location_en', ''),
      nullif(s->>'location_he', ''),
      nullif(s->>'location_ar', '')
    from jsonb_array_elements(_sessions) as s;
  end if;

  return jsonb_build_object('status', 'ok');
end;
$function$;

-- ---------------------------------------------------------------------------
-- Registration. 0070's body, plus: auto-accept writes the accepted row in
-- the same transaction, so the student is in immediately. Approval leaves
-- only the registration, which is the "applied, waiting" state.
-- ---------------------------------------------------------------------------
create or replace function public.register_for_event(_event_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  _event public.events%rowtype;
  _registered_count int;
  _code text;
begin
  select * into _event from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'event_not_found');
  end if;

  if _event.approval_status <> 'approved' then
    return jsonb_build_object('status', 'not_published');
  end if;

  if not public.event_is_visible_to(_event_id, auth.uid()) then
    return jsonb_build_object('status', 'not_visible');
  end if;

  if now() > _event.ends_at then
    return jsonb_build_object('status', 'ended');
  end if;

  if exists (
    select 1 from public.event_registrations
    where event_id = _event_id and user_id = auth.uid() and status = 'registered'
  ) then
    return jsonb_build_object('status', 'already');
  end if;

  if coalesce(_event.registration_closed, false) then
    return jsonb_build_object('status', 'registration_closed');
  end if;

  if _event.capacity is not null then
    select count(*) into _registered_count
    from public.event_registrations
    where event_id = _event_id and status = 'registered';

    if _registered_count >= _event.capacity then
      return jsonb_build_object('status', 'full');
    end if;
  end if;

  loop
    _code := encode(gen_random_bytes(9), 'hex');
    exit when not exists (select 1 from public.event_registrations where code = _code);
  end loop;

  insert into public.event_registrations (event_id, user_id, status, registered_at, code)
  values (_event_id, auth.uid(), 'registered', now(), _code)
  on conflict (event_id, user_id)
  do update set status = 'registered', registered_at = now();

  if coalesce(_event.acceptance_mode, 'auto') = 'auto' then
    insert into public.program_accepted_participants
      (event_id, user_id, added_by, from_registration)
    values (_event_id, auth.uid(), auth.uid(), true)
    on conflict (event_id, user_id) do nothing;
  end if;

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.register_for_event(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Check-in. Approval events only admit people already on the accepted list.
-- A scan must not walk-up-register someone who is still waiting. Auto events
-- keep the walk-up join and record that join as an acceptance too.
-- Body matches 0061 apart from that gate.
-- ---------------------------------------------------------------------------
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

  if coalesce(_event.acceptance_mode, 'auto') = 'approval'
     and not exists (
       select 1 from public.program_accepted_participants
       where event_id = _event.id and user_id = auth.uid()
     ) then
    return jsonb_build_object(
      'status', 'not_accepted',
      'points', 0,
      'event_title', _event.title
    );
  end if;

  select * into _registered from public.event_registrations
    where event_id = _token_row.event_id and user_id = auth.uid();

  if not found or _registered.status <> 'registered' then
    loop
      _code := encode(gen_random_bytes(9), 'hex');
      exit when not exists (select 1 from public.event_registrations where code = _code);
    end loop;

    insert into public.event_registrations (event_id, session_id, user_id, status, registered_at, code)
    values (_token_row.event_id, _token_row.session_id, auth.uid(), 'registered', now(), _code)
    on conflict (event_id, user_id) do update
      set status = 'registered', registered_at = now(), session_id = excluded.session_id;
  end if;

  if coalesce(_event.acceptance_mode, 'auto') = 'auto' then
    insert into public.program_accepted_participants
      (event_id, user_id, added_by, from_registration)
    values (_event.id, auth.uid(), auth.uid(), true)
    on conflict (event_id, user_id) do nothing;
  end if;

  insert into public.event_attendance (event_id, session_id, user_id, points_awarded)
  values (_token_row.event_id, _token_row.session_id, auth.uid(), _event.points);

  insert into public.point_transactions (user_id, amount, reason, metadata)
  values (auth.uid(), _event.points, 'event_attendance', jsonb_build_object('event_id', _event.id, 'event_title', _event.title));

  return jsonb_build_object('status', 'ok', 'points', _event.points, 'event_title', _event.title);
end;
$$;

-- ---------------------------------------------------------------------------
-- Manual attendance. Same gate: an approval event will not check in a
-- student who has only registered. 0081's body otherwise unchanged.
-- ---------------------------------------------------------------------------
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

  if coalesce(v_event.acceptance_mode, 'auto') = 'approval'
     and not exists (
       select 1 from public.program_accepted_participants
       where event_id = _event_id and user_id = v_user_id
     ) then
    return jsonb_build_object('status', 'not_accepted', 'points', 0, 'event_title', v_title);
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
