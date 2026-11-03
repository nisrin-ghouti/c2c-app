-- Free up today's meeting slots so the daily limits can be retested.
--
-- RUN STEP 1 FIRST and check the rows before running step 2.
--
-- Preferred approach is to mark the proposals `declined`, not delete them:
-- the limits only count `status = 'accepted'`, so declining frees the slot
-- while keeping the history, the chat cards, and any check-in rows intact.

-- ============================================================ STEP 1: LOOK
-- Every accepted meeting whose CAMPUS day is today. These are the rows
-- consuming today's limits.
select
  p.id,
  p.status,
  p.scheduled_at,
  p.scheduled_at at time zone 'Asia/Jerusalem' as starts_campus_local,
  public.campus_date(p.scheduled_at)           as campus_day,
  p.chat_id,
  p.proposed_by
from public.meeting_proposals p
where p.status = 'accepted'
  and public.campus_date(p.scheduled_at) = public.campus_date()
order by p.scheduled_at;

-- ========================================================== STEP 2: RELEASE
-- Paste the ids from step 1 that you want to free up. Explicit ids, not a
-- date filter — so a mistake in the WHERE clause can't sweep up real meetings.
--
-- update public.meeting_proposals
-- set status = 'declined'
-- where id in (
--   '00000000-0000-0000-0000-000000000000',
--   '00000000-0000-0000-0000-000000000000'
-- );

-- ================================================ STEP 3: CONFIRM (re-run 1)
-- Step 1 should now return nothing for the pair you cleared.

-- ------------------------------------------------------------- HARD DELETE
-- Only if you truly want the rows gone. Removes the chat card and any
-- check-in/scan-token rows first, or their foreign keys block the delete.
-- Same rule: explicit ids.
--
-- with doomed as (select unnest(array[
--   '00000000-0000-0000-0000-000000000000'::uuid
-- ]) as id)
-- delete from public.meeting_checkins   where proposal_id in (select id from doomed);
-- delete from public.meeting_scan_tokens where proposal_id in (select id from doomed);
-- delete from public.meeting_completions where proposal_id in (select id from doomed);
-- delete from public.chat_messages
--   where (metadata->>'proposal_id')::uuid in (select id from doomed);
-- delete from public.meeting_proposals  where id in (select id from doomed);
