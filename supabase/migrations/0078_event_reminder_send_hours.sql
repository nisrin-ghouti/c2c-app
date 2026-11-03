-- Send event reminders at a civilised hour instead of at midnight.
--
-- 0076 decided "is this event tomorrow / today?" by comparing campus-local
-- CALENDAR DATES, and ran the dispatcher hourly. Those two facts together put
-- every reminder at midnight: the date comparison becomes true the instant the
-- campus date rolls over, and the next hourly run is the one at campus 00:00.
-- So students got a "your event is tomorrow" push at three minutes past
-- midnight. Correct by the spec, useless in practice.
--
-- The window rule is unchanged — still the calendar day before and the day
-- itself, still campus-local via `campus_date()`. Only the HOUR each kind is
-- allowed to go out is new:
--
--   tomorrow -> 18:00-21:59 campus time, the day before
--   today    -> from 08:00 campus time, and only while the event is still
--               ahead of the viewer
--
-- Why ranges rather than a single hour. The dispatcher still runs hourly, so a
-- range means one missed run (a deploy, a restart, a locked table) doesn't
-- silently drop that day's reminders — the next hour picks them up, and the
-- `event_reminder_sends` ledger still guarantees exactly one per person. A
-- single `= 18` would make the 18:00 run the only chance all day.
--
-- The upper bound on `tomorrow` (21:59) is the whole point of this migration:
-- without it, a student registering at 23:30 would get their "tomorrow" push
-- at 23:30. After 22:00 the reminder is simply skipped; they still get the
-- "today" one in the morning.
--
-- `today` has no upper bound but gains `starts_at > now()`, which fixes a
-- second 0076 bug: a student registering at 16:00 for an event that ran at
-- 09:00 was sent "your event is today" about something already finished. It
-- also means an event starting before 08:00 gets no "today" reminder at all —
-- deliberately, since the only honest time to send one would be after it had
-- begun. Those events are covered by the 18:00 reminder the evening before.
--
-- Knock-on effect worth knowing: the centre-screen popup renders from the
-- notification row, so it cannot appear before the row is written. A student
-- opening the app at 10:00 the day before an event now sees no popup — the
-- "tomorrow" row doesn't exist until 18:00. That is the accepted cost of not
-- pushing at midnight; the in-app notification centre behaves the same way.
--
-- Idempotent: re-running replaces the function. The cron job and the ledger
-- from 0076 are untouched, so this needs no re-scheduling.

create or replace function public.dispatch_event_reminders()
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _now_campus timestamp := now() at time zone 'Asia/Jerusalem';
  _today      date := public.campus_date();
  _tomorrow   date := _today + 1;
  _hour       int  := extract(hour from _now_campus)::int;
  _sent       integer := 0;
  _batch      integer;
  _kind       text;
  _day        date;
begin
  foreach _kind in array array['today', 'tomorrow'] loop
    _day := case when _kind = 'today' then _today else _tomorrow end;

    -- The hour gate. Everything else below is 0076's body verbatim.
    if _kind = 'tomorrow' and _hour not between 18 and 21 then
      continue;
    end if;
    if _kind = 'today' and _hour < 8 then
      continue;
    end if;

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
        -- New in 0078: never tell someone an event is "today" once it has
        -- already started.
        and (_kind <> 'today' or e.starts_at > now())
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

-- Verify the gate without waiting for the cron:
--
--   select extract(hour from (now() at time zone 'Asia/Jerusalem'))::int
--          as campus_hour;
--
-- Calling it outside 18:00-21:59 sends no `tomorrow` rows and outside 08:00+
-- no `today` rows — a 0 return at 14:00 means the gate is working, not that
-- the job is broken:
--
--   select public.dispatch_event_reminders();
--
--   select kind, event_day, count(*), min(created_at), max(created_at)
--   from public.event_reminder_sends
--   group by kind, event_day order by event_day desc;
