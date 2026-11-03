-- What is actually stored in the session translation columns? Read-only.
--
-- The previous check only told us the columns were non-null. If the function
-- skipped them (it only fills EMPTY columns), a column can be non-null and
-- still contain the original Hebrew.

select
  s.id,
  e.title            as event,
  s.title            as canonical_title,
  s.title_en,
  s.title_he,
  s.title_ar,
  s.location         as canonical_location,
  s.location_en,
  s.location_he,
  s.location_ar
from public.event_sessions s
join public.events e on e.id = s.event_id
order by e.created_at desc, s.starts_at
limit 10;
