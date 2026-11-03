-- Multi-value Faculty + Field of Study for profiles.
--
-- The app previously stored a single `faculty` and `field_of_study` (text) per
-- profile. Users can now pick MULTIPLE of each, with at least one Field of
-- Study required. We add two array columns and keep the original single columns
-- populated with the first selected value so existing single-value consumers
-- (Matches filtering, candidate cards, home student previews) keep working
-- unchanged.
--
-- Run this once in the Supabase SQL editor (or via `supabase db push`).

begin;

-- 1. New array columns (default empty array, never null).
alter table public.profiles
  add column if not exists faculties       text[] not null default '{}'::text[],
  add column if not exists fields_of_study text[] not null default '{}'::text[];

-- 2. Backfill arrays from the existing single-value columns so current users
--    don't lose data (only when the single column has a non-empty value).
update public.profiles
   set faculties = array[faculty]
 where faculty is not null
   and faculty <> ''
   and (faculties is null or cardinality(faculties) = 0);

update public.profiles
   set fields_of_study = array[field_of_study]
 where field_of_study is not null
   and field_of_study <> ''
   and (fields_of_study is null or cardinality(fields_of_study) = 0);

commit;

-- 3. Field of Study option list.
--
-- Admins curate selectable values in `public.option_lists` keyed by `list_type`.
-- The app now uses a new list_type = 'field_of_study'. If your `option_lists`
-- table has a CHECK constraint enumerating allowed list_type values, add
-- 'field_of_study' to it. (If there's no such constraint, this is a no-op and
-- you can skip it — the app can already insert the new type.)
--
-- Example (adjust the constraint name/values to match your schema):
--
--   alter table public.option_lists drop constraint if exists option_lists_list_type_check;
--   alter table public.option_lists add constraint option_lists_list_type_check
--     check (list_type in (
--       'faculty','field_of_study','degree','hobby','interest',
--       'language','event_category','benefit_category'
--     ));
--
-- Optionally seed a starter Field of Study list (edit labels to taste):
--
--   insert into public.option_lists (list_type, label, sort_order, active)
--   values
--     ('field_of_study', 'Computer Science', 1, true),
--     ('field_of_study', 'Business Administration', 2, true),
--     ('field_of_study', 'Psychology', 3, true),
--     ('field_of_study', 'Law', 4, true),
--     ('field_of_study', 'Medicine', 5, true);
