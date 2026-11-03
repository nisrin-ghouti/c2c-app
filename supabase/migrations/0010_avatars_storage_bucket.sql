-- Storage for profile pictures (spec: Complete Profile includes a profile
-- picture). The app uploads to `avatars/<user_id>/<file>` and saves the
-- resulting public URL in `profiles.avatar_url` (column already exists).
--
-- Public read so any student can see other students' photos in Matches/chat;
-- writes are restricted to the owner's own folder.
--
-- Idempotent: safe to re-run.

-- 1. Bucket (public read) -----------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- 2. Policies -------------------------------------------------------------
-- Ownership is by first path segment: 'avatars/<user_id>/photo.jpg'.

drop policy if exists avatars_public_read   on storage.objects;
drop policy if exists avatars_owner_insert  on storage.objects;
drop policy if exists avatars_owner_update  on storage.objects;
drop policy if exists avatars_owner_delete  on storage.objects;

-- Anyone (even signed out) may view avatars — they're public URLs.
create policy avatars_public_read
  on storage.objects for select
  using (bucket_id = 'avatars');

-- A user may only write inside their own folder.
create policy avatars_owner_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy avatars_owner_update
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy avatars_owner_delete
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
