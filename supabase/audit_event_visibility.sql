-- EVENT VISIBILITY AUDIT
-- Run in the Supabase SQL editor. A normal client is subject to 0069's
-- restrictive policy and can only see events it is entitled to, which is
-- exactly why this cannot be checked from the app.

-- 1. The distribution. Anything that is NOT 'everyone' changed behaviour when
--    0069 ran: before it, `visibility` was written but never enforced, so
--    those events were visible to everyone regardless. They are now correctly
--    restricted — which is the intended fix, but worth seeing deliberately
--    rather than discovering later.
select
  e.visibility,
  e.approval_status,
  count(*)                                              as events,
  count(*) filter (where e.ends_at > now())             as still_upcoming
from public.events e
group by e.visibility, e.approval_status
order by e.visibility, e.approval_status;

-- 2. The restricted ones in detail, with whether their targeting is usable.
--    A 'specific_faculties' event with NO target rows is treated as
--    unrestricted by event_is_visible_to() (0069 chose that over burying the
--    event); one WITH targets is visible only to those faculties.
select
  e.id,
  e.title,
  e.visibility,
  e.ends_at > now()                                      as upcoming,
  (select count(*) from public.event_visibility_targets t
    where t.event_id = e.id and t.target_type = 'faculty') as faculty_targets,
  (select string_agg(t.target_value, ', ')
     from public.event_visibility_targets t
    where t.event_id = e.id and t.target_type = 'faculty') as targeted_faculties,
  -- How many students actually qualify. 0 on an upcoming event means nobody
  -- will ever see it.
  (select count(*) from public.profiles p
    where p.deleted_at is null
      and public.is_student_eligible(p.id)
      and public.event_is_visible_to(e.id, p.id))        as students_who_can_see_it
from public.events e
where coalesce(e.visibility, 'everyone') <> 'everyone'
order by e.ends_at desc;
