-- Why are session translations still null? Read-only.
--
-- Compares an event's OWN translation columns against its sessions'. The
-- event and its sessions are filled by the same function call, so:
--
--   event filled + sessions null  -> the function ran, but the deployed copy
--                                    is still the old one without the session
--                                    fan-out (redeploy translate-content)
--   event null   + sessions null  -> the function was never invoked, or it
--                                    failed (check Edge Functions -> Logs)
--   both filled                   -> it works; you were looking at an older
--                                    event created before the deploy

select
  e.id                                as event_id,
  e.title                             as event_title,
  e.created_at,
  (e.title_en is not null)            as event_title_en_filled,
  (e.title_he is not null)            as event_title_he_filled,
  (e.location_en is not null)         as event_location_en_filled,
  count(s.id)                         as sessions,
  count(s.title_en)                   as session_title_en_filled,
  count(s.title_he)                   as session_title_he_filled,
  count(s.location)                   as sessions_with_a_location,
  count(s.location_en)                as session_location_en_filled
from public.events e
left join public.event_sessions s on s.event_id = e.id
group by e.id, e.title, e.created_at, e.title_en, e.title_he, e.location_en
order by e.created_at desc
limit 5;
