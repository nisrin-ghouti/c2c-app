-- Benefit profile fields + image storage.
--
-- Spec (Benefits & Digital Cards): the benefit's full profile shows title,
-- business name, benefit description, points, business description, how to
-- redeem, image, category, and location (text + optional maps link). Only
-- title/description/category/points/image/business-name existed before.
--
-- Also adds a public bucket so admins can upload a benefit image directly
-- instead of pasting a URL.
--
-- Idempotent: safe to re-run.

-- 1. New benefit columns ---------------------------------------------------
alter table public.benefits
  add column if not exists business_description text,
  add column if not exists how_to_redeem       text,
  add column if not exists external_link       text,
  add column if not exists location            text,
  add column if not exists maps_link           text;

comment on column public.benefits.business_description is 'About the partner business.';
comment on column public.benefits.how_to_redeem is 'Redemption instructions shown to the student.';
comment on column public.benefits.external_link is 'Instagram / website / Facebook etc.';
comment on column public.benefits.location is 'Human-readable address.';
comment on column public.benefits.maps_link is 'Optional Google Maps URL for the location.';

-- 2. Benefit image bucket --------------------------------------------------
-- Public read (students see images in the catalog); only admins may write.
insert into storage.buckets (id, name, public)
values ('benefit-images', 'benefit-images', true)
on conflict (id) do update set public = true;

drop policy if exists benefit_images_public_read on storage.objects;
create policy benefit_images_public_read
  on storage.objects for select
  using (bucket_id = 'benefit-images');

drop policy if exists benefit_images_admin_write on storage.objects;
create policy benefit_images_admin_write
  on storage.objects for all to authenticated
  using (bucket_id = 'benefit-images' and public.is_admin())
  with check (bucket_id = 'benefit-images' and public.is_admin());
