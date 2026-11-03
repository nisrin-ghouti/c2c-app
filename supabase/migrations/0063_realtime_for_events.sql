-- Fix: an event edited in the admin panel doesn't change in the app until the
-- app is killed and reopened.
--
-- `eventListProvider` is autoDispose, but the Home screen watches it for as
-- long as the app is running, so it never actually disposes — the first fetch
-- of a session is the only fetch of that session. Pull-to-refresh on the
-- events list was the sole way to get fresh data short of killing the process,
-- which is exactly what was reported.
--
-- The app now subscribes to changes on these two tables and drops its cached
-- event lists whenever a row moves (see `eventsLiveRefreshProvider`). That
-- subscription only receives anything if the tables belong to the
-- `supabase_realtime` publication — same requirement that 0005 documented for
-- chat messages, and the same failure mode if it's missed: the subscription
-- connects, reports healthy, and silently never fires.
--
-- `event_sessions` is included because a Program's meetings carry their own
-- title, time and location; editing just a session is an event change from
-- the student's point of view even though the `events` row never moves.
--
-- Realtime still honours RLS — a student only receives rows they could
-- already SELECT.
--
-- Idempotent: re-running is a no-op.

do $$
declare
  _table text;
begin
  foreach _table in array array['events', 'event_sessions'] loop
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = _table
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        _table
      );
      raise notice 'realtime: added public.% to supabase_realtime', _table;
    else
      raise notice 'realtime: public.% was already published', _table;
    end if;
  end loop;
end $$;

-- Confirm what's published now:
--
--   select schemaname, tablename
--   from pg_publication_tables
--   where pubname = 'supabase_realtime'
--   order by tablename;
