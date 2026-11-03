-- Program session title/location translations were never written by
-- create_event_or_program / update_event_or_program. Both RPCs deleted and
-- re-inserted event_sessions with only (title, starts_at, ends_at, location),
-- so every program save wiped title_en/he/ar and location_en/he/ar.
--
-- That left the admin Sessions editor falling back to the canonical (often
-- Hebrew) title while Content language was English. Persist the per-locale
-- columns the admin client already sends in the sessions jsonb.

alter table public.event_sessions
  add column if not exists title_en text,
  add column if not exists title_he text,
  add column if not exists title_ar text,
  add column if not exists location_en text,
  add column if not exists location_he text,
  add column if not exists location_ar text;

-- ---------------------------------------------------------------------------
-- create_event_or_program: same body as 0055, sessions insert now includes
-- translation columns.
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
begin
  select exists(
    select 1 from public.user_roles where user_id = auth.uid() and role in ('host','admin')
  ) into _can_create;

  if not _can_create then
    return jsonb_build_object('status', 'forbidden');
  end if;

  insert into public.events (
    title, description, category, location, starts_at, ends_at, points,
    image_url, organizer_name, organizer_description, external_link,
    created_by, event_kind, approval_status, visibility, capacity,
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

-- ---------------------------------------------------------------------------
-- update_event_or_program: same body as 0082 (group-manager edit), sessions
-- insert now includes translation columns.
-- ---------------------------------------------------------------------------
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
