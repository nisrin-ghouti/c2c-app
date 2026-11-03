-- Event reminders: one the day before, one on the day.
--
-- Both land in the same three places every other notification in this app
-- already uses, so nothing new is built to carry them:
--
--   * `notifications` row            -> the in-app notification centre
--   * the Database Webhook on that   -> `send-push` -> the device push
--   * the app reads the same row     -> the once-per-day centre-screen popup
--                                       (`EventReminderPopup`, persisted in
--                                       SharedPreferences per user/event/day)
--
-- WHAT COUNTS AS "TOMORROW" AND "TODAY"
-- Both are campus-local, via `campus_date()` (0060) — the same function every
-- meeting daily-limit already uses. The database runs in UTC, so a plain
-- `starts_at::date` puts an event at 00:30 Tuesday campus time on Monday and
-- would remind the wrong day by one.
--
-- WHO GETS ONE
-- The event's live registrants (`event_registrations.status = 'registered'`),
-- minus soft-deleted profiles, minus anyone the event is no longer visible to
-- (`event_is_visible_to`, 0069 — run that first). Registrants rather than the
-- whole campus: a reminder is about something you signed up for, and
-- "everyone" is what the publish notification already covers.
--
-- NO DUPLICATES, AND RESCHEDULING HANDLED
-- `event_reminder_sends` records one row per (event, user, kind, event day),
-- and the insert claims it with `on conflict do nothing` BEFORE the
-- notification is written — so the notification only exists for a claim that
-- was actually won. Running the dispatcher twice a minute, or twice by hand,
-- produces nothing the second time.
--
-- Keying on the event's own day (not on the date the job ran) is what makes
-- rescheduling work: move an event from Thursday to Friday and its
-- (event, user, kind) pair has a day it has never been reminded for, so the
-- new reminders go out; the old day's rows stay as history and are never
-- matched again. A cancelled (deleted) event takes its rows with it via
-- `on delete cascade`, and a cancelled REGISTRATION simply stops matching.
--
-- A reminder is never sent late. Both windows are "the event's day is today /
-- tomorrow, campus time", so if the dispatcher doesn't run on the relevant day
-- that day's reminder is skipped rather than queued — which is also what the
-- popup rule requires (a popup for a day the user never opened the app must
-- not appear afterwards).
--
-- SCHEDULING
-- Section 4 registers a `pg_cron` job. If the extension isn't available the
-- migration still applies and says so — the function is then callable by hand
-- or from any external scheduler. See the note there.
--
-- Idempotent: re-running adds no rows and re-registers the same job.

-- 1. Allow the two new type labels ------------------------------------------
-- Superset of 0066's list (which is itself 0014's plus 0036's) plus the two
-- reminder types. Restating the whole list is required: the CHECK enumerates
-- every permitted value, so anything omitted here would start being rejected.
alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array[
    'points_earned', 'new_message', 'meeting_proposal', 'event_pending_approval',
    'event_published', 'benefit_published', 'report_submitted', 'event_decision',
    'group_meeting_pending', 'benefit_redeemed', 'benefit_card_resent',
    'survey_published',
    'event_reminder_tomorrow', 'event_reminder_today'
  ]));

-- 2. The dedupe ledger ------------------------------------------------------
create table if not exists public.event_reminder_sends (
  event_id   uuid not null references public.events (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  -- 'tomorrow' | 'today'
  kind       text not null check (kind in ('tomorrow', 'today')),
  -- The event's campus-local start date this reminder was about. Part of the
  -- key so a rescheduled event is remindable again; see the note at the top.
  event_day  date not null,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id, kind, event_day)
);

comment on table public.event_reminder_sends is
  'One row per reminder actually sent, keyed by the event''s own campus-local '
  'start date. Claimed before the notification is written, so it is the thing '
  'that makes dispatch_event_reminders() safe to run repeatedly.';

create index if not exists event_reminder_sends_user_idx
  on public.event_reminder_sends (user_id, created_at desc);

alter table public.event_reminder_sends enable row level security;

-- Readable by its owner only; nobody writes it but the dispatcher, which is
-- security definer. The app doesn't actually need to read it (it tracks popup
-- state locally and renders from `notifications`), but a user being able to
-- see their own send history costs nothing and keeps the table debuggable
-- from a signed-in session.
drop policy if exists event_reminder_sends_select_own on public.event_reminder_sends;
create policy event_reminder_sends_select_own
  on public.event_reminder_sends for select
  to authenticated
  using (user_id = auth.uid());

grant select on public.event_reminder_sends to authenticated;

-- 3. The dispatcher ---------------------------------------------------------
-- Returns how many reminders it sent, so a cron run or a manual call says
-- what it did.
create or replace function public.dispatch_event_reminders()
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _today    date := public.campus_date();
  _tomorrow date := _today + 1;
  _sent     integer := 0;
  _batch    integer;
  _kind     text;
  _day      date;
begin
  -- Two passes over the same shape, one per window.
  foreach _kind in array array['today', 'tomorrow'] loop
    _day := case when _kind = 'today' then _today else _tomorrow end;

    -- One statement does the whole window: claim every (event, user) pair
    -- that hasn't been reminded for this event day, then write exactly one
    -- notification per claim that was won. A pair already in the ledger
    -- produces no claim and therefore no notification, which is what makes
    -- this safe to re-run.
    with due as (
      select
        e.id          as event_id,
        r.user_id     as user_id,
        e.title       as title,
        e.title_en    as title_en,
        e.title_he    as title_he,
        e.title_ar    as title_ar,
        e.location    as location,
        e.location_en as location_en,
        e.location_he as location_he,
        e.location_ar as location_ar,
        e.starts_at   as starts_at,
        e.ends_at     as ends_at
      from public.events e
      join public.event_registrations r
        on r.event_id = e.id
       and r.status = 'registered'
      join public.profiles p
        on p.id = r.user_id
       and p.deleted_at is null
      where e.approval_status = 'approved'
        and public.campus_date(e.starts_at) = _day
        -- An event the student can no longer open shouldn't nag them about
        -- itself. Depends on 0069.
        and public.event_is_visible_to(e.id, r.user_id)
    ),
    claimed as (
      insert into public.event_reminder_sends (event_id, user_id, kind, event_day)
      select d.event_id, d.user_id, _kind, _day
      from due d
      on conflict (event_id, user_id, kind, event_day) do nothing
      returning event_id, user_id
    )
    insert into public.notifications (user_id, type, data)
    select
      c.user_id,
      case when _kind = 'today'
        then 'event_reminder_today'
        else 'event_reminder_tomorrow'
      end,
      jsonb_build_object(
        'event_id',    d.event_id,
        'kind',        _kind,
        'event_day',   _day,
        -- Both the canonical text and every translation, so `send-push` can
        -- pick the device's language and the popup can pick the app's. Same
        -- shape 0075 gave the publish notifications.
        'title',       d.title,
        'title_en',    d.title_en,
        'title_he',    d.title_he,
        'title_ar',    d.title_ar,
        'location',    d.location,
        'location_en', d.location_en,
        'location_he', d.location_he,
        'location_ar', d.location_ar,
        'starts_at',   d.starts_at,
        'ends_at',     d.ends_at
      )
    from claimed c
    join due d
      on d.event_id = c.event_id
     and d.user_id = c.user_id;

    get diagnostics _batch = row_count;
    _sent := _sent + _batch;
  end loop;

  return _sent;
end;
$$;

revoke all on function public.dispatch_event_reminders() from public;

-- Deliberately NOT granted to `authenticated`. It fans out rows into other
-- people's notification feeds, so only the scheduler (which runs as the
-- function owner via pg_cron) and the service role may call it.

-- 4. Scheduling -------------------------------------------------------------
-- Hourly on the hour. Hourly rather than daily because:
--   * the "today" reminder should reach someone who registers on the morning
--     of the event, which a single nightly run would miss entirely;
--   * an event moved to tomorrow should be remindable within the hour.
-- The ledger makes the extra runs free — after the first run of a given
-- campus day, every subsequent run in that window claims nothing.
--
-- If pg_cron isn't enabled on this project the migration still applies and
-- raises a notice. Enable it under Database -> Extensions, then re-run this
-- file (it is idempotent), or drive `dispatch_event_reminders()` from any
-- external scheduler — a GitHub Action, a Supabase scheduled function, or a
-- cron box calling it with the service-role key.
do $$
begin
  begin
    create extension if not exists pg_cron;
  exception when others then
    raise notice
      'pg_cron not available (%). Event reminders will not fire until '
      'dispatch_event_reminders() is scheduled some other way.', sqlerrm;
    return;
  end;

  -- cron.schedule upserts by job name, so re-running just rewrites the same
  -- job rather than stacking duplicates.
  perform cron.schedule(
    'dispatch-event-reminders',
    '0 * * * *',
    'select public.dispatch_event_reminders();'
  );
  raise notice 'cron: dispatch-event-reminders scheduled hourly';
exception when others then
  raise notice
    'could not schedule dispatch-event-reminders (%); schedule '
    'dispatch_event_reminders() manually.', sqlerrm;
end $$;

-- Check what it would do / has done:
--
--   select public.dispatch_event_reminders();
--
--   select kind, event_day, count(*) from public.event_reminder_sends
--   group by kind, event_day order by event_day desc;
--
--   select jobname, schedule, active from cron.job
--   where jobname = 'dispatch-event-reminders';
