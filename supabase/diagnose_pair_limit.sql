-- Why did a second same-day proposal get through? Run these in order.
-- Read-only.

-- 1. What day does the server think it is, and what days do the recent
--    proposals fall on? If campus_day differs from campus_today for the
--    accepted one, the pair check was comparing different days.
select public.campus_date() as campus_today, current_date as utc_today;

select
  p.id,
  p.chat_id,
  p.status,
  p.proposed_by,
  p.scheduled_at,
  public.campus_date(p.scheduled_at) as campus_day
from public.meeting_proposals p
order by p.proposed_at desc
limit 10;

-- 2. Who are the members of the chat those proposals belong to?
--    (paste a chat_id from above)
-- select m from public.chat_member_ids('<CHAT_ID>') m;

-- 3. Ask the helper directly, with the two user ids from step 1's proposed_by
--    plus the other member from step 2.
--    Expect TRUE if an accepted meeting exists for that pair on that day.
-- select public.has_accepted_meeting_with('<USER_A>', '<USER_B>', public.campus_date());

-- 4. Is the deployed propose_meeting the one from 0060?
--    All three should be true.
select
  proname,
  position('daily_pair_limit' in prosrc) > 0 as has_pair_check,
  position('campus_date'      in prosrc) > 0 as uses_campus_date,
  position('has_accepted_meeting_with' in prosrc) > 0 as calls_helper
from pg_proc
where proname = 'propose_meeting';
