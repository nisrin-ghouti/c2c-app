-- Why is there no QR on an accepted meeting? Read-only.
--
-- The QR only exists while the meeting's window is open:
--   now >= scheduled_at AND now < ends_at
-- Before the start time the My Events card is deliberately not tappable.
--
-- Read `window_open_now`. If it is false, the app is behaving correctly and
-- the question is whether the stored times are what the students intended.
select
  p.id,
  p.status,
  p.scheduled_at,
  p.ends_at,
  now()                                        as now_utc,
  (now() >= p.scheduled_at and now() < p.ends_at) as window_open_now,
  p.scheduled_at at time zone 'Asia/Jerusalem' as starts_campus_local,
  p.ends_at      at time zone 'Asia/Jerusalem' as ends_campus_local,
  now()          at time zone 'Asia/Jerusalem' as now_campus_local,
  p.proposed_at                                as created_at
from public.meeting_proposals p
where p.status = 'accepted'
order by p.proposed_at desc
limit 10;

-- Compare `starts_campus_local` with the time the students actually picked.
--   * matches, and window_open_now is false  -> just not started yet
--   * three hours LATER than intended        -> row written before the
--                                               timezone fix; expected for
--                                               anything created earlier today
--   * matches, window open, still no QR      -> a real bug, tell me
