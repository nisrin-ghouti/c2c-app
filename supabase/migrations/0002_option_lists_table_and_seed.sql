-- Option lists: the admin-curated selectable values shown as chips in profile
-- completion / editing and elsewhere (Faculties, Fields of study, Interests,
-- Hobbies, Languages, Degrees, event/benefit categories).
--
-- Symptom this fixes: every picker on "Complete your profile" shows
-- "Couldn't load options" because the `option_lists` query fails — the table
-- is missing, or RLS doesn't let a normal (non-admin) signed-in user read it.
--
-- Safe to run more than once (idempotent). Run in the Supabase SQL editor.

-- 1. Table -----------------------------------------------------------------
create table if not exists public.option_lists (
  id         uuid primary key default gen_random_uuid(),
  list_type  text        not null,
  label      text        not null,
  sort_order integer     not null default 0,
  active     boolean     not null default true,
  created_by uuid        references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (list_type, label)
);

-- 2. Table-level privileges ------------------------------------------------
-- SEPARATE from RLS: without these GRANTs the app's `authenticated` role gets
-- "permission denied for table option_lists" (a hard error) no matter what the
-- RLS policies say. The SQL editor runs as `postgres` and bypasses both, so
-- the table looks fine there while the app fails. RLS (below) still decides
-- which ROWS each user may see/modify.
grant select on public.option_lists to authenticated, anon;
grant insert, update, delete on public.option_lists to authenticated;

-- 3. Row-level security ----------------------------------------------------
alter table public.option_lists enable row level security;

-- Any signed-in user may READ options (needed for profile completion/editing).
drop policy if exists option_lists_select_authenticated on public.option_lists;
create policy option_lists_select_authenticated
  on public.option_lists
  for select
  to authenticated
  using (true);

-- Only admins may create/update/delete options (matches the app's admin panel).
-- "Admin" = has the 'admin' role in user_roles, or is_super_admin on profiles.
drop policy if exists option_lists_write_admin on public.option_lists;
create policy option_lists_write_admin
  on public.option_lists
  for all
  to authenticated
  using (
    exists (
      select 1 from public.user_roles ur
      where ur.user_id = auth.uid() and ur.role = 'admin'
    )
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and coalesce(p.is_super_admin, false)
    )
  )
  with check (
    exists (
      select 1 from public.user_roles ur
      where ur.user_id = auth.uid() and ur.role = 'admin'
    )
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and coalesce(p.is_super_admin, false)
    )
  );

-- 2b. Allow the new 'field_of_study' list type ----------------------------
-- The existing table has a CHECK constraint enumerating the allowed list_type
-- values, which predates 'field_of_study'. Recreate it to include the new
-- type (plus every type the app already uses). Adjust the list if your schema
-- differs, but it must contain every list_type currently in the table.
alter table public.option_lists drop constraint if exists option_lists_list_type_check;
alter table public.option_lists add constraint option_lists_list_type_check
  check (list_type in (
    'faculty', 'field_of_study', 'degree', 'hobby', 'interest',
    'language', 'event_category', 'benefit_category'
  ));

-- 3. Starter data ----------------------------------------------------------
-- Edit these labels to whatever your institution uses. The NOT EXISTS guard
-- keeps re-runs from creating duplicates and works whether or not the table
-- already had a unique constraint. At least one 'field_of_study' row is
-- REQUIRED — it's the mandatory field on Complete Profile.
insert into public.option_lists (list_type, label, sort_order)
select v.list_type, v.label, v.sort_order
from (values
  ('field_of_study', 'Computer Science',        1),
  ('field_of_study', 'Business Administration',  2),
  ('field_of_study', 'Psychology',               3),
  ('field_of_study', 'Law',                       4),
  ('field_of_study', 'Medicine',                  5),
  ('field_of_study', 'Engineering',               6),
  ('field_of_study', 'Education',                 7),

  ('faculty', 'Engineering',        1),
  ('faculty', 'Humanities',         2),
  ('faculty', 'Social Sciences',    3),
  ('faculty', 'Natural Sciences',   4),
  ('faculty', 'Medicine',           5),
  ('faculty', 'Law',                6),
  ('faculty', 'Business',           7),

  ('interest', 'Technology',   1),
  ('interest', 'Music',        2),
  ('interest', 'Sports',       3),
  ('interest', 'Art',          4),
  ('interest', 'Volunteering', 5),
  ('interest', 'Gaming',       6),
  ('interest', 'Travel',       7),
  ('interest', 'Reading',      8),

  ('hobby', 'Photography', 1),
  ('hobby', 'Cooking',     2),
  ('hobby', 'Hiking',      3),
  ('hobby', 'Painting',    4),
  ('hobby', 'Running',     5),
  ('hobby', 'Chess',       6),
  ('hobby', 'Dancing',     7),

  ('language', 'Hebrew',   1),
  ('language', 'Arabic',   2),
  ('language', 'English',  3),
  ('language', 'Russian',  4),
  ('language', 'French',   5),
  ('language', 'Spanish',  6),

  ('degree', 'Bachelor''s', 1),
  ('degree', 'Master''s',   2),
  ('degree', 'PhD',         3)
) as v(list_type, label, sort_order)
where not exists (
  select 1 from public.option_lists o
  where o.list_type = v.list_type and o.label = v.label
);
