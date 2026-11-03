-- INCIDENT: new events don't appear in the app, though their push arrives.
--
-- The push proves the row exists and is approved: `notify_event_published`
-- fires on the approval transition and is SECURITY DEFINER, so it bypasses
-- RLS entirely. The app's list, by contrast, is a plain `select` on `events`
-- as the signed-in student — so it is subject to RLS.
--
-- Migration 0069 is the only thing in this batch that can hide an event. It
-- did TWO things, and either can cause this:
--
--   a) `alter table public.events enable row level security`
--      If RLS was previously DISABLED on this table, every student could read
--      every event because nothing was being enforced. Turning it on means
--      only rows granted by a PERMISSIVE policy are visible. If no permissive
--      SELECT policy covers `authenticated`, students now see NOTHING.
--
--   b) the `events_visibility_restrictive` policy
--      RESTRICTIVE policies AND with the permissive ones — they can only
--      subtract. If `event_is_visible_to()` returns false (or raises) for a
--      row, it disappears.
--
-- Read-only. One result set, so the SQL editor shows it all.

with rls as (
  select
    'A. is RLS enabled on events?'                      as check_name,
    case when c.relrowsecurity then 'YES' else 'NO' end as value,
    case
      when c.relrowsecurity
        then 'Only rows granted by a PERMISSIVE policy are visible. See B.'
      else 'RLS off: every grantee reads every row. 0069 did not take effect.'
    end as note
  from pg_class c
  where c.oid = 'public.events'::regclass
),
permissive as (
  -- THE KEY ROW. If this count is 0 while RLS is on, that is the bug:
  -- restrictive policies cannot grant, so students see nothing at all.
  select
    'B. permissive SELECT policies for authenticated' as check_name,
    count(*)::text                                    as value,
    coalesce(string_agg(policyname, ', '), '(none)')  as note
  from pg_policies
  where schemaname = 'public'
    and tablename = 'events'
    and permissive = 'PERMISSIVE'
    and cmd in ('SELECT', 'ALL')
    and ('authenticated' = any (roles) or 'public' = any (roles))
),
restrictive as (
  select
    'C. restrictive SELECT policies'                 as check_name,
    count(*)::text                                   as value,
    coalesce(string_agg(policyname, ', '), '(none)') as note
  from pg_policies
  where schemaname = 'public'
    and tablename = 'events'
    and permissive = 'RESTRICTIVE'
    and cmd in ('SELECT', 'ALL')
),
fn as (
  select
    'D. does event_is_visible_to exist?' as check_name,
    case
      when to_regprocedure('public.event_is_visible_to(uuid,uuid)') is not null
        then 'YES' else 'NO'
    end as value,
    case
      when to_regprocedure('public.can_manage_event(uuid,uuid)') is not null
        then 'can_manage_event(uuid,uuid) present'
      else 'can_manage_event(uuid,uuid) MISSING -> the policy raises on every row'
    end as note
),
-- E/F: does the predicate actually pass for a real student and the newest
-- events? Picks the most recently active student as the sample viewer.
sample_user as (
  select p.id, p.full_name
  from public.profiles p
  where p.deleted_at is null
    and public.is_student_eligible(p.id)
  order by p.created_at desc
  limit 1
),
visibility_sample as (
  select
    'E. newest events visible to sample student' as check_name,
    count(*) filter (
      where public.event_is_visible_to(e.id, (select id from sample_user))
    )::text || ' of ' || count(*)::text as value,
    'sample student: ' || coalesce((select full_name from sample_user), '(none found)')
      as note
  from (
    select id from public.events
    where approval_status = 'approved'
    order by created_at desc
    limit 20
  ) e
),
-- G: the OTHER bug, independent of the migrations. The app sends
-- `DateTime.now().toIso8601String()` — a LOCAL time with no offset — which
-- Postgres reads as UTC, so events ending within the next `utc_offset` hours
-- are filtered out client-side. Fixed in the app, needs a new build.
clock_window as (
  select
    'F. events hidden by the app clock bug' as check_name,
    count(*)::text                          as value,
    'approved events ending between now and now + local offset; '
      || 'these are invisible in the DEPLOYED build regardless of RLS' as note
  from public.events
  where approval_status = 'approved'
    and ends_at >= now()
    and ends_at < now() + (
      select (utc_offset) from pg_timezone_names where name = 'Asia/Jerusalem'
    )
)
select * from rls
union all select * from permissive
union all select * from restrictive
union all select * from fn
union all select * from visibility_sample
union all select * from clock_window;
