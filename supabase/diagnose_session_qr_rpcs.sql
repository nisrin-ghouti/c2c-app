-- The two QR functions live in the baseline, not in any migration file, so
-- their bodies can't be reviewed from the repo. Per-session barcodes depend on
-- both of them honouring `_session_id`:
--   start_event_qr        -> must mint a token carrying session_id
--   set_event_qr_enabled  -> must write event_sessions.qr_enabled, NOT events'
-- Read-only.
select p.oid::regprocedure as signature,
       pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('start_event_qr', 'set_event_qr_enabled')
order by 1;
