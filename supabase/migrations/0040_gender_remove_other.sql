-- "Other" is being removed as a gender choice, keeping only
-- male/female/undisclosed. Existing rows must be migrated before the CHECK
-- constraint is tightened, or the ALTER would fail against live data.

update public.profiles set gender = 'undisclosed' where gender = 'other';

alter table public.profiles drop constraint if exists profiles_gender_check;
alter table public.profiles add constraint profiles_gender_check
  check (gender is null or gender in ('male', 'female', 'undisclosed'));
