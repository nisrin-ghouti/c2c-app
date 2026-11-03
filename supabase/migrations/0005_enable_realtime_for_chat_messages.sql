-- Fix: a sent chat message doesn't appear until you leave the thread and
-- come back.
--
-- The app subscribes to messages with a Supabase realtime stream
-- (ChatRemoteDataSource.watchMessages -> .stream(primaryKey: ['id'])). A
-- realtime stream only receives live INSERT/UPDATE/DELETE events if its table
-- belongs to the `supabase_realtime` publication. Without that, the stream
-- still does its one-off initial fetch — which is why re-entering the screen
-- (a fresh subscription, hence a fresh fetch) shows the missing message.
--
-- Adding the table to the publication makes new messages arrive live.
-- Realtime still honours RLS: users only receive rows they could SELECT.
--
-- Idempotent: re-running is a no-op.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_messages'
  ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end $$;

-- Check which tables are currently published to realtime:
--
--   select schemaname, tablename
--   from pg_publication_tables
--   where pubname = 'supabase_realtime'
--   order by tablename;
--
-- If other realtime-backed features misbehave the same way (e.g. the QR
-- meeting session in MatchesRemoteDataSource.watchSession), add those tables
-- here too using the same guarded block.
