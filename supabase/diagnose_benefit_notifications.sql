-- Why isn't a new benefit producing a notification?
--
-- The whole chain already exists in code (trigger 0014 → `notifications` row →
-- Database Webhook → `send-push` → FCM; the Dart side parses, renders and
-- deep-links `benefit_published`). So when it doesn't fire, the break is in the
-- live database or the webhook config, not in the app. This locates which.
--
-- Read-only. Run the whole file and look at each result in turn.

-- 1. Is the trigger actually installed on `benefits`?
--    Expect one row: trg_notify_benefit_published. If this is empty, migration
--    0014 never landed here — that alone explains total silence.
select tgname      as trigger_name,
       tgenabled   as enabled,          -- 'O' = enabled, 'D' = DISABLED
       pg_get_triggerdef(oid) as definition
from pg_trigger
where tgrelid = 'public.benefits'::regclass
  and not tgisinternal
order by tgname;

-- 2. Does the fan-out helper exist, and does the type pass the CHECK?
--    A missing 'benefit_published' label makes every insert fail silently
--    inside the trigger.
select to_regprocedure('public.notify_benefit_published()') is not null as trigger_fn_exists,
       to_regprocedure('public.notify_all_students(text,jsonb,uuid)') is not null as fanout_fn_exists,
       (select pg_get_constraintdef(oid)
        from pg_constraint
        where conrelid = 'public.notifications'::regclass
          and contype = 'c'
          and pg_get_constraintdef(oid) ilike '%benefit_published%'
       ) as type_check_allows_benefit_published;

-- 3. Have any benefit_published rows EVER been written, and when?
--    Rows present but no push => the problem is the webhook / send-push.
--    No rows at all => the problem is the trigger (see 1 and 2).
select count(*)        as benefit_published_rows,
       max(created_at) as most_recent
from public.notifications
where type = 'benefit_published';

-- 4. Compare against events, which you say DO notify. If event_published has
--    recent rows and benefit_published has none, the difference is the trigger,
--    not the push plumbing — both share the same webhook.
select type, count(*) as rows, max(created_at) as most_recent
from public.notifications
where type in ('event_published', 'benefit_published', 'survey_published')
group by type
order by type;

-- 5. Recently created benefits vs. their notification rows.
--    A benefit created `active = false` legitimately notifies only when it is
--    later flipped to active — that is by design, not a bug.
select b.id,
       b.title,
       b.active,
       b.created_at,
       exists (
         select 1 from public.notifications n
         where n.type = 'benefit_published'
           and n.data ->> 'benefit_id' = b.id::text
       ) as notified
from public.benefits b
order by b.created_at desc
limit 10;

-- 6. Is anyone able to receive a push at all? Zero device tokens means the
--    in-app bell will still work while the phone stays silent.
select count(*) as device_tokens, count(distinct user_id) as users_with_a_device
from public.device_tokens;
