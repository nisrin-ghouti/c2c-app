-- Verify a self-service account deletion actually removed the user.
-- Replace the email below, then run. All three checks should report PASS.

with target as (select 'Niso3259@gmail.com'::text as email)

-- 1. The auth user must be gone.
select
  '1. auth.users' as check_name,
  case when count(*) = 0 then 'PASS - no auth user' else 'FAIL - still present' end as result,
  count(*) as rows_found
from auth.users, target
where lower(auth.users.email) = lower(target.email)

union all

-- 2. The profile must be gone.
select
  '2. profiles',
  case when count(*) = 0 then 'PASS - no profile' else 'FAIL - still present' end,
  count(*)
from public.profiles, target
where lower(public.profiles.email) = lower(target.email)

union all

-- 3. Campus content authored by deleted users must SURVIVE with a null
--    author — that is the deliberate policy, not a leak. A non-zero count
--    here is expected if the deleted account had created anything.
select
  '3. content kept (author nulled)',
  'INFO - see rows_found',
  (select count(*) from public.benefits where created_by is null)
  + (select count(*) from public.surveys  where created_by is null)
  + (select count(*) from public.reports  where reporter_id is null
                                             or reported_user_id is null);
