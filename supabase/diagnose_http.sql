-- What actually happened when the trigger called send-push?
--
-- The trigger uses supabase_functions.http_request, which dispatches through
-- pg_net. Every response pg_net receives lands in net._http_response, so this
-- shows whether the call went out, what came back, and whether it timed out.
--
-- NOTE: pg_net prunes this table after a few hours. If it's empty, publish a
-- test event first (that creates notifications), then re-run this immediately.

select r.id,
       r.created,
       r.status_code,
       r.timed_out,
       r.error_msg,
       left(r.content, 300) as response_body
from net._http_response r
order by r.id desc
limit 20;
