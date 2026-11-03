-- Remove one user completely (including an admin).
--
-- DESTRUCTIVE AND IRREVERSIBLE. Run section 1 first and read it, then run
-- section 2 or 3 — not the whole file at once.
--
-- Do NOT hand-write deletes against individual tables for this. 34 foreign
-- keys point at `profiles`; `purge_user_account` (migration 0058) already
-- knows all of them and which are DELETE vs SET NULL — campus content the
-- user authored stays published with the authorship link severed, moderation
-- history is anonymised rather than destroyed, personal data is removed.
-- Every table added since (0071, 0076, 0079, 0081) is ON DELETE CASCADE, so
-- it is covered automatically when the profile row goes.
--
-- Deleting the profile is only HALF the job. The account also has a row in
-- `auth.users`, which is what lets the person sign in. Leave it and they can
-- still log in — and `ensureProfileExists` will hand them a fresh blank
-- profile on next launch, so the account quietly comes back. Section 3
-- removes both.

-- ===========================================================================
-- 1. PRE-FLIGHT — run this alone, read the output, then stop and check it
-- ===========================================================================
-- Replace the email below. Confirms you have the right person, shows what
-- they own, and tells you whether deleting them is even permitted.
with target as (
  select id, full_name, email, is_super_admin
  from public.profiles
  where lower(email) = lower('REPLACE_WITH_EMAIL')
)
select
  t.id,
  t.full_name,
  t.email,
  coalesce(t.is_super_admin, false)                       as is_super_admin,
  (select string_agg(r.role::text, ', ')
     from public.user_roles r where r.user_id = t.id)      as roles,
  -- An admin account is usually also the author of campus content. None of
  -- this is deleted (authorship is set to null), but it is worth seeing.
  (select count(*) from public.events   e where e.created_by = t.id) as events_created,
  (select count(*) from public.surveys  s where s.created_by = t.id) as surveys_created,
  (select count(*) from public.benefits b where b.created_by = t.id) as benefits_created,
  -- The important safety number: how many OTHER admins remain afterwards.
  (select count(*) from public.user_roles r
    where r.role = 'admin'::app_role and r.user_id <> t.id)          as other_admins_left
from target t;

-- STOP. Before continuing, confirm all three:
--   * exactly one row came back, and it is the right person;
--   * `is_super_admin` is false — if true, STOP. Migration 0011 protects that
--     account by spec ("cannot be deleted, cannot have its administrator
--     privileges removed"), and the role trigger will raise if you try;
--   * `other_admins_left` is at least 1, or you are locking yourself out of
--     the admin console.


-- ===========================================================================
-- 2. THE SAFER OPTION — revoke admin, keep the account
-- ===========================================================================
-- If what you actually want is "this person should no longer be an admin",
-- this is the whole job. Reversible, destroys nothing, and keeps the events
-- and surveys they authored attributed to them.
--
--   delete from public.user_roles
--   where user_id = (select id from public.profiles
--                    where lower(email) = lower('REPLACE_WITH_EMAIL'))
--     and role = 'admin'::app_role;
--
-- Note they may hold a 'student' or 'host' role too; the above removes only
-- the admin grant. An account with NO roles at all is treated as a student by
-- `is_student_eligible` (0033), so they would land in the student app.


-- ===========================================================================
-- 3. FULL DELETION — profile, then the login
-- ===========================================================================
-- Both statements, in this order, in one go. Running only the first leaves a
-- sign-in-capable account with no profile.
--
-- Uncomment to use.

-- select public.purge_user_account(
--   (select id from public.profiles where lower(email) = lower('REPLACE_WITH_EMAIL'))
-- );
--
-- delete from auth.users
-- where lower(email) = lower('REPLACE_WITH_EMAIL');

-- `purge_user_account` raises if passed null, so a mistyped email fails loudly
-- rather than silently doing nothing — but the `delete from auth.users` would
-- just delete zero rows, so check the email in section 1 first.


-- ===========================================================================
-- 4. VERIFY — nothing should come back
-- ===========================================================================
-- select 'profile' as where_, count(*) from public.profiles
--   where lower(email) = lower('REPLACE_WITH_EMAIL')
-- union all
-- select 'auth user', count(*) from auth.users
--   where lower(email) = lower('REPLACE_WITH_EMAIL');
