-- Adds the `gender` field the spec requires on the Complete Profile screen
-- (alongside picture, faculty, field of study, degree type, year, hobbies,
-- interests, languages and the free-text intro).
--
-- Stored as a stable key rather than a display string so the label can be
-- translated into Hebrew/Arabic/English in the app. The app maps:
--   'male' | 'female' | 'other' | 'undisclosed'
--
-- Nullable: gender is not required to complete a profile (only a field of
-- study is), and 'undisclosed' must stay a deliberate choice, not a default.
--
-- Idempotent: safe to re-run.

alter table public.profiles
  add column if not exists gender text;

-- Guard against typos/unknown values while still allowing NULL.
alter table public.profiles drop constraint if exists profiles_gender_check;
alter table public.profiles add constraint profiles_gender_check
  check (gender is null or gender in ('male', 'female', 'other', 'undisclosed'));
