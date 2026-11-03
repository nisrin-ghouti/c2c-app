-- Wire the 5 Benefit Profile columns (added in 0012) into the create/update
-- RPCs. Without this, `create_benefit`/`update_benefit` insert only the
-- original columns, so business_description / how_to_redeem / external_link /
-- location / maps_link silently save as null even though the form sends them.
--
-- Bodies are the existing functions verbatim (same admin check, same
-- nullif-on-empty handling, same return shape) with the new columns added.

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
    created_by
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
    auth.uid()
  )
  returning id into _new_id;

  return jsonb_build_object('status', 'ok', 'id', _new_id);
end;
$function$;

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
    maps_link = nullif(_benefit->>'maps_link', '')
  where id = _id;

  return jsonb_build_object('status', 'ok');
end;
$function$;
