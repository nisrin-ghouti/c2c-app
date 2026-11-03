-- Enable realtime for the QR "connect" flow.
--
-- MatchesRemoteDataSource.watchSession streams a single `meeting_sessions` row:
-- the host shows a QR code and waits for `claimed_at` to become non-null when
-- the other student scans it. Like chat_messages (see 0005), the table must
-- belong to the `supabase_realtime` publication or the host never receives the
-- UPDATE and waits forever — no celebration, no points awarded.
--
-- This stream watches UPDATEs (not just INSERTs), so the table also needs
-- REPLICA IDENTITY FULL: without it Postgres only puts the primary key in the
-- WAL for updates, and Realtime can't evaluate RLS against the row's other
-- columns to decide whether the subscriber may receive it.
--
-- Idempotent: re-running is a no-op.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'meeting_sessions'
  ) then
    alter publication supabase_realtime add table public.meeting_sessions;
  end if;
end $$;

-- Required for UPDATE events to carry the full row (see note above).
alter table public.meeting_sessions replica identity full;
