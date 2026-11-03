-- Lets the app show a full event as full *before* the student taps Register.
--
-- `register_for_event` (0038 → 0044) has always refused a registration once
-- `count(event_registrations where status = 'registered') >= events.capacity`,
-- returning `{"status": "full"}`. But nothing could ask that question ahead of
-- time: the app reads `event_registrations` filtered to `user_id = auth.uid()`
-- (that's all RLS allows a student), so the Register button looked live right
-- up to the tap, and "this event is full" arrived as an error afterwards.
--
-- This exposes the one number the UI needs and nothing more: a count per
-- event. No registrant identity, no row contents — the same aggregate the
-- capacity check already makes server-side, and `events.capacity` it gets
-- compared against is readable by every student already.
--
-- `security definer` because the point is to count rows the caller cannot
-- SELECT. The body only ever aggregates, and only over the event ids it is
-- handed, so there is nothing here for a caller to widen.
--
-- Returns a jsonb object of event_id → count, and deliberately omits events
-- with no registrations rather than mapping them to 0; the Dart side treats a
-- missing key as 0, which keeps the payload small for a long list.
--
-- Idempotent: re-running replaces the function.
create or replace function public.get_event_registration_counts(
  _event_ids uuid[]
)
returns jsonb
language sql
stable
security definer
set search_path to 'public', 'extensions'
as $$
  select coalesce(
    jsonb_object_agg(counted.event_id, counted.registered),
    '{}'::jsonb
  )
  from (
    select r.event_id, count(*) as registered
    from public.event_registrations r
    where r.event_id = any(_event_ids)
      and r.status = 'registered'
    group by r.event_id
  ) as counted;
$$;

revoke all on function public.get_event_registration_counts(uuid[]) from public;
grant execute on function public.get_event_registration_counts(uuid[]) to authenticated;
