-- Run AFTER 0059_block_meetings_over_daily_limits.sql. Read-only.
--
-- RUN THE SECTIONS ONE AT A TIME. Section 0 first: sections 1-3 assume 0059
-- applied successfully, and section 3 errors outright if the helpers are
-- missing rather than telling you why.

-- 0. DID 0059 APPLY AT ALL? -------------------------------------------------
-- Expect two rows. Zero rows means 0059 never ran, or failed partway through
-- (its statements run in order, so an early failure leaves the rest unapplied)
-- — re-run the migration and read the error it reports.
select
  proname as function_name,
  pg_get_function_identity_arguments(oid) as args
from pg_proc
where proname in ('accepted_meeting_partners_on', 'has_accepted_meeting_with');

-- 1. NO ACCIDENTAL OVERLOADS ------------------------------------------------
-- `create or replace` only replaces a function whose signature matches. If the
-- deployed `respond_to_meeting_proposal` had different argument types, 0059
-- created a SECOND function instead of replacing it, and PostgREST will start
-- failing with an ambiguity error on every accept/decline.
--
-- Read the `overloads` column, not the row count. One row per DISTINCT
-- function name is correct and expected. The failure case is two rows sharing
-- the same name, which shows as overloads = 2 — that name has a duplicate to
-- drop.
select
  proname                                   as function_name,
  pg_get_function_identity_arguments(oid)   as arguments,
  prosecdef                                 as security_definer,
  count(*) over (partition by proname)      as overloads
from pg_proc
where proname in (
  'respond_to_meeting_proposal',
  'propose_meeting',
  'has_accepted_meeting_with',
  'accepted_meeting_partners_on'
)
order by proname;

-- 2. THE CHECKS ARE ACTUALLY IN THE DEPLOYED BODIES -------------------------
-- Both should report true for every column. If any is false, 0059 did not
-- fully apply.
select
  proname as function_name,
  position('daily_pair_limit'    in prosrc) > 0 as blocks_same_pair_per_day,
  position('daily_partner_limit' in prosrc) > 0 as blocks_five_partners,
  position('accepted_meeting_partners_on' in prosrc) > 0 as uses_shared_helper
from pg_proc
where proname in ('propose_meeting', 'respond_to_meeting_proposal')
order by proname;

-- 3. THE HELPERS RETURN SENSIBLE ANSWERS ------------------------------------
-- Lists today's accepted meetings per student. A student appearing with
-- partners_today >= 5 is at the cap; anyone at 2+ for the same partner on one
-- day would mean the pair rule is not holding.
select
  p.id            as student_id,
  p.full_name,
  public.accepted_meeting_partners_on(p.id, current_date) as partners_today
from public.profiles p
where public.accepted_meeting_partners_on(p.id, current_date) > 0
order by partners_today desc
limit 20;
