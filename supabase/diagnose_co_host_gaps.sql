-- Which event functions would still turn a co-host away?
--
-- Run after 0062_event_co_hosts.sql. Anything this returns is a function whose
-- body compares `created_by` to `auth.uid()` without also consulting
-- `host_event_access` (directly or through `can_manage_event`) — i.e. a place
-- where a co-host is treated as a stranger.
--
-- Expected result after 0062: zero rows. `start_event_qr`,
-- `set_event_qr_enabled` and `get_event_stats` predate the migration series and
-- exist only in the live database, so this is the only way to see how they
-- guard themselves.
select
  p.oid::regprocedure::text as function_signature,
  pg_get_functiondef(p.oid)  as definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and pg_get_functiondef(p.oid) like '%created_by%auth.uid()%'
  and pg_get_functiondef(p.oid) not like '%host_event_access%'
  and pg_get_functiondef(p.oid) not like '%can_manage_event%'
order by 1;
