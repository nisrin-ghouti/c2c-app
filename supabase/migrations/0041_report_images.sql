-- Reports currently support only text (reason/details) — add support for
-- attaching evidence screenshots. `details` becoming mandatory is enforced
-- client-side only (same as `reason` already is); the column stays nullable
-- text at the DB layer.

alter table public.reports add column if not exists image_urls text[] not null default '{}';

insert into storage.buckets (id, name, public)
values ('report-images', 'report-images', true)
on conflict (id) do nothing;

-- Mirrors event-images' policy shape exactly: public read, any authenticated
-- user can write (a student reporting someone needs to upload their own
-- evidence, same as any student creating an event needs to upload its image).
drop policy if exists report_images_public_read on storage.objects;
create policy report_images_public_read
  on storage.objects for select
  to public
  using (bucket_id = 'report-images');

drop policy if exists report_images_write on storage.objects;
create policy report_images_write
  on storage.objects for all
  to authenticated
  using (bucket_id = 'report-images')
  with check (bucket_id = 'report-images');
