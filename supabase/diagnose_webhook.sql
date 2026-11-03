-- Is anything wired to fire when a notification row is created?
--
-- A Supabase "Database Webhook" is implemented as a normal trigger that calls
-- supabase_functions.http_request(...). So if the webhook exists, it shows up
-- here as a trigger on public.notifications. No rows = nothing calls send-push,
-- which means notifications are created but never delivered.

select t.tgname                                as trigger_name,
       case t.tgenabled
         when 'O' then 'enabled'
         when 'D' then 'DISABLED'
         when 'R' then 'enabled (replica)'
         when 'A' then 'enabled (always)'
       end                                     as status,
       pg_get_triggerdef(t.oid)                as definition
from pg_trigger t
join pg_class c   on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where not t.tgisinternal
  and n.nspname = 'public'
  and c.relname = 'notifications'
order by t.tgname;
