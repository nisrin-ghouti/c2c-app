-- Why is no push arriving on iOS? Read-only, ONE result set.
--
-- Supabase's SQL editor only returns the LAST statement's rows, so this is a
-- single query. Delivery path:
--   notifications INSERT -> trigger -> send-push -> FCM -> APNs -> device
--
-- Replace the email below with the account whose phone should be receiving.

with me as (
  select id from public.profiles
  where lower(email) = lower('may.massalha1@gmail.com')
)
select '1. device tokens by platform' as check_name,
       platform                       as detail,
       count(*)::text                 as value,
       max(updated_at)::text          as newest
from public.device_tokens
group by platform

union all
select '2. MY tokens (none = never registered)',
       d.platform,
       left(d.token, 16) || '…',
       d.updated_at::text
from public.device_tokens d
join me on me.id = d.user_id

union all
select '3. notifications for me, last 7d',
       n.type,
       count(*)::text,
       max(n.created_at)::text
from public.notifications n
join me on me.id = n.user_id
where n.created_at > now() - interval '7 days'
group by n.type

union all
select '4. event_published for ANY user, last 7d',
       '(all users)',
       count(*)::text,
       max(created_at)::text
from public.notifications
where type = 'event_published'
  and created_at > now() - interval '7 days'

order by check_name;
