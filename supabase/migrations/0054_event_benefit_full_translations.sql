-- Extends the per-locale translation columns added in
-- 0049_event_benefit_translations.sql (title/description only) to every
-- other free-text field on events and benefits: location, organizer_name,
-- organizer_description (events); location, partner_business_name,
-- business_description, how_to_redeem (benefits). `category` is excluded —
-- it's a curated option_lists value (event_category/benefit_category),
-- already translated via that table's own label_ar/label_he columns.

alter table public.events
  add column if not exists location_ar text,
  add column if not exists location_he text,
  add column if not exists organizer_name_ar text,
  add column if not exists organizer_name_he text,
  add column if not exists organizer_description_ar text,
  add column if not exists organizer_description_he text;

alter table public.benefits
  add column if not exists location_ar text,
  add column if not exists location_he text,
  add column if not exists partner_business_name_ar text,
  add column if not exists partner_business_name_he text,
  add column if not exists business_description_ar text,
  add column if not exists business_description_he text,
  add column if not exists how_to_redeem_ar text,
  add column if not exists how_to_redeem_he text;

-- Re-create create/update_event_or_program (bodies verbatim from
-- 0049_event_benefit_translations.sql) with the 6 new columns wired into
-- the insert/update, following the existing `nullif(_x->>'y', '')` idiom.
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
    organizer_description_ar, organizer_description_he
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
    nullif(_event->>'organizer_description_he', '')
  )
  returning id into _new_id;

  if _event ? 'visibility_targets' then
    insert into public.event_visibility_targets (event_id, target_type, target_value)
    select _new_id, t->>'target_type', t->>'target_value'
    from jsonb_array_elements(_event->'visibility_targets') as t;
  end if;

  if _sessions is not null then
    insert into public.event_sessions (event_id, title, starts_at, ends_at, location)
    select _new_id, s->>'title', (s->>'starts_at')::timestamptz, (s->>'ends_at')::timestamptz, nullif(s->>'location','')
    from jsonb_array_elements(_sessions) as s;
  end if;

  return jsonb_build_object('status', 'ok', 'id', _new_id);
end;
$function$;

create or replace function public.update_event_or_program(_event_id uuid, _event jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  _row public.events%rowtype;
  _can_manage boolean;
begin
  select * into _row from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  select
    exists(select 1 from public.user_roles where user_id = auth.uid() and role = 'admin')
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
    -- editing an already-approved event sends it back for re-review
    approval_status = case when approval_status = 'approved' then 'pending' else approval_status end,
    rejection_reason = case when approval_status = 'approved' then null else rejection_reason end
  where id = _event_id;

  delete from public.event_visibility_targets where event_id = _event_id;
  if _event ? 'visibility_targets' then
    insert into public.event_visibility_targets (event_id, target_type, target_value)
    select _event_id, t->>'target_type', t->>'target_value'
    from jsonb_array_elements(_event->'visibility_targets') as t;
  end if;

  return jsonb_build_object('status', 'ok');
end;
$function$;

-- Re-create create/update_benefit (bodies verbatim from
-- 0049_event_benefit_translations.sql) with the 8 new columns wired in the
-- same way.
create or replace function public.create_benefit(_benefit jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  _new_id uuid;
begin
  if not exists (select 1 from user_roles where user_id = auth.uid() and role = 'admin') then
    return jsonb_build_object('status', 'forbidden');
  end if;

  insert into benefits (
    title, description, category, point_cost, image_url, partner_business_name,
    business_description, how_to_redeem, external_link, location, maps_link,
    created_by, title_ar, title_he, description_ar, description_he,
    location_ar, location_he, partner_business_name_ar, partner_business_name_he,
    business_description_ar, business_description_he, how_to_redeem_ar, how_to_redeem_he
  )
  values (
    _benefit->>'title',
    nullif(_benefit->>'description', ''),
    nullif(_benefit->>'category', ''),
    (_benefit->>'point_cost')::int,
    nullif(_benefit->>'image_url', ''),
    nullif(_benefit->>'partner_business_name', ''),
    nullif(_benefit->>'business_description', ''),
    nullif(_benefit->>'how_to_redeem', ''),
    nullif(_benefit->>'external_link', ''),
    nullif(_benefit->>'location', ''),
    nullif(_benefit->>'maps_link', ''),
    auth.uid(),
    nullif(_benefit->>'title_ar', ''),
    nullif(_benefit->>'title_he', ''),
    nullif(_benefit->>'description_ar', ''),
    nullif(_benefit->>'description_he', ''),
    nullif(_benefit->>'location_ar', ''),
    nullif(_benefit->>'location_he', ''),
    nullif(_benefit->>'partner_business_name_ar', ''),
    nullif(_benefit->>'partner_business_name_he', ''),
    nullif(_benefit->>'business_description_ar', ''),
    nullif(_benefit->>'business_description_he', ''),
    nullif(_benefit->>'how_to_redeem_ar', ''),
    nullif(_benefit->>'how_to_redeem_he', '')
  )
  returning id into _new_id;

  return jsonb_build_object('status', 'ok', 'id', _new_id);
end;
$function$;

-- The digital-card ("wallet card") read path joins through to `benefits`
-- but never selected its translation columns, so a redeemed card always
-- showed the canonical-language text regardless of app locale. Re-create
-- verbatim (body from 0034_benefit_card_management.sql) with those columns
-- added.
drop function if exists public.list_my_digital_cards();
create function public.list_my_digital_cards()
returns table(
  id uuid, benefit_id uuid, title text, description text, category text,
  image_url text, partner_business_name text, qr_token text,
  redemption_code text, status text, points_spent integer,
  redeemed_at timestamp with time zone, created_at timestamp with time zone,
  title_ar text, title_he text, description_ar text, description_he text,
  partner_business_name_ar text, partner_business_name_he text
)
language sql
security definer
set search_path to 'public'
as $$
  select dc.id, dc.benefit_id, b.title, b.description, b.category,
         b.image_url, b.partner_business_name, dc.qr_token, dc.redemption_code, dc.status,
         dc.points_spent, dc.redeemed_at, dc.created_at,
         b.title_ar, b.title_he, b.description_ar, b.description_he,
         b.partner_business_name_ar, b.partner_business_name_he
  from digital_cards dc
  join benefits b on b.id = dc.benefit_id
  where dc.user_id = auth.uid()
  order by dc.created_at desc;
$$;

create or replace function public.update_benefit(_id uuid, _benefit jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not exists (select 1 from user_roles where user_id = auth.uid() and role = 'admin') then
    return jsonb_build_object('status', 'forbidden');
  end if;
  if not exists (select 1 from benefits where id = _id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  update benefits set
    title = coalesce(_benefit->>'title', title),
    description = nullif(_benefit->>'description', ''),
    category = nullif(_benefit->>'category', ''),
    point_cost = coalesce((_benefit->>'point_cost')::int, point_cost),
    image_url = nullif(_benefit->>'image_url', ''),
    partner_business_name = nullif(_benefit->>'partner_business_name', ''),
    business_description = nullif(_benefit->>'business_description', ''),
    how_to_redeem = nullif(_benefit->>'how_to_redeem', ''),
    external_link = nullif(_benefit->>'external_link', ''),
    location = nullif(_benefit->>'location', ''),
    maps_link = nullif(_benefit->>'maps_link', ''),
    title_ar = nullif(_benefit->>'title_ar', ''),
    title_he = nullif(_benefit->>'title_he', ''),
    description_ar = nullif(_benefit->>'description_ar', ''),
    description_he = nullif(_benefit->>'description_he', ''),
    location_ar = nullif(_benefit->>'location_ar', ''),
    location_he = nullif(_benefit->>'location_he', ''),
    partner_business_name_ar = nullif(_benefit->>'partner_business_name_ar', ''),
    partner_business_name_he = nullif(_benefit->>'partner_business_name_he', ''),
    business_description_ar = nullif(_benefit->>'business_description_ar', ''),
    business_description_he = nullif(_benefit->>'business_description_he', ''),
    how_to_redeem_ar = nullif(_benefit->>'how_to_redeem_ar', ''),
    how_to_redeem_he = nullif(_benefit->>'how_to_redeem_he', '')
  where id = _id;

  return jsonb_build_object('status', 'ok');
end;
$function$;
