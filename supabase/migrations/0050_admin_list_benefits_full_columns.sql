-- `admin_list_benefits()` only ever returned 8 columns (id, title,
-- description, category, point_cost, image_url, partner_business_name,
-- active) even though `benefits` has held `business_description`,
-- `how_to_redeem`, `external_link`, `location`, `maps_link` since migration
-- 0012, and `create_benefit`/`update_benefit` have saved them since 0019 —
-- the admin catalog's "edit" dialog was silently reopening with those
-- fields blank on every existing row. Fixed here while also wiring in the
-- new title_ar/title_he/description_ar/description_he translation columns
-- (0049), since both are the same "the read side hasn't kept up with the
-- write side" class of bug.
drop function if exists public.admin_list_benefits();

create or replace function public.admin_list_benefits()
returns table(
  id uuid,
  title text,
  description text,
  category text,
  point_cost integer,
  image_url text,
  partner_business_name text,
  business_description text,
  how_to_redeem text,
  external_link text,
  location text,
  maps_link text,
  active boolean,
  title_ar text,
  title_he text,
  description_ar text,
  description_he text
)
language sql
security definer
set search_path to 'public'
as $function$
  select b.id, b.title, b.description, b.category, b.point_cost,
         b.image_url, b.partner_business_name, b.business_description,
         b.how_to_redeem, b.external_link, b.location, b.maps_link, b.active,
         b.title_ar, b.title_he, b.description_ar, b.description_he
  from benefits b
  where exists (select 1 from user_roles where user_id = auth.uid() and role = 'admin')
  order by b.created_at desc;
$function$;

grant execute on function public.admin_list_benefits() to authenticated;
