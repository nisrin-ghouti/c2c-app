-- Verify the meeting limits are actually enforced in PRODUCTION.
--
-- Read-only. Checks two different things:
--   A. that the deployed function bodies contain the rules at all
--   B. that real awarded points have never violated them
--
-- (B) is the stronger evidence: it audits what actually happened, not what
-- the code claims it would do.

-- ============================================================ A. deployed code
-- The repo's migration only matters if it was actually applied. This reads the
-- live function bodies. Every flag should be true for scan_meeting_qr.
select
  proname as function_name,
  position('partners_today' in prosrc) > 0 as has_5_partner_cap,
  position('v_today_pair'   in prosrc) > 0 as has_same_day_pair_check,
  position('meeting_second' in prosrc) > 0 as has_point_tiers,
  position('25'             in prosrc) > 0 as mentions_25
from pg_proc
where proname in ('scan_meeting_qr', 'award_meeting_points');

-- ============================================================ B. historical audit
-- Each of the three queries below should return ZERO rows. Any row is a real
-- violation that already happened in production.

-- B1. Same pair awarded meeting points more than once on the same day.
--     Expected: no rows.
select
  'B1 same pair twice in one day' as violation,
  user_id,
  metadata->>'other_user_id' as partner_id,
  created_at::date as day,
  count(*) as awards
from public.point_transactions
where reason in ('meeting_first', 'meeting_second', 'meeting_repeat')
  and metadata->>'other_user_id' is not null
group by user_id, metadata->>'other_user_id', created_at::date
having count(*) > 1;

-- B2. A user awarded meeting points for more than 5 distinct partners in a day.
--     Expected: no rows.
select
  'B2 more than 5 partners in one day' as violation,
  user_id,
  created_at::date as day,
  count(distinct metadata->>'other_user_id') as distinct_partners
from public.point_transactions
where reason in ('meeting_first', 'meeting_second', 'meeting_repeat')
  and metadata->>'other_user_id' is not null
group by user_id, created_at::date
having count(distinct metadata->>'other_user_id') > 5;

-- B3. Point amounts that don't match the tier they claim.
--     Expected: no rows. (first=25, second=20, repeat=10)
select
  'B3 wrong amount for tier' as violation,
  reason,
  amount,
  count(*) as occurrences
from public.point_transactions
where (reason = 'meeting_first'  and amount <> 25)
   or (reason = 'meeting_second' and amount <> 20)
   or (reason = 'meeting_repeat' and amount <> 10)
group by reason, amount;

-- ============================================================ C. tier ordering
-- Informational, not a pass/fail: for each pair, the Nth award should carry
-- the matching tier. Row 1 -> meeting_first, row 2 -> meeting_second,
-- row 3+ -> meeting_repeat. Any mismatch means the tier counter is wrong.
select
  user_id,
  metadata->>'other_user_id' as partner_id,
  created_at,
  reason,
  amount,
  row_number() over (
    partition by user_id, metadata->>'other_user_id' order by created_at
  ) as nth_meeting_with_partner
from public.point_transactions
where reason in ('meeting_first', 'meeting_second', 'meeting_repeat')
  and metadata->>'other_user_id' is not null
order by user_id, partner_id, created_at
limit 100;
