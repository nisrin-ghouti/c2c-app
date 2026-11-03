-- Fix: a digital card keeps showing its barcode after the partner scans it,
-- until the student backs out of the screen and comes back.
--
-- `CardDetailScreen` is handed a `DigitalCard` snapshot by whoever pushed it
-- and never re-reads the row, so the `status -> 'redeemed'` write made by
-- `redeem-benefit` is invisible to the screen that is, at that exact moment,
-- being held up to the scanner. Everything downstream of the data is already
-- correct: `DigitalCardView` hides the QR and flips the status label the
-- instant `isRedeemed` is true, and the repository already maps
-- `status = 'redeemed'` onto it. Only the freshness was missing.
--
-- The app now subscribes to `digital_cards` while a card is open and refetches
-- the wallet when a row moves (see `digitalCardsLiveRefreshProvider`). That
-- subscription receives nothing unless the table belongs to the
-- `supabase_realtime` publication — the same requirement 0005 documented for
-- chat and 0063 for events, and the same silent failure if it is missed: the
-- subscription connects, reports healthy, and never fires.
--
-- Realtime still honours RLS, and `digital_cards` rows are already restricted
-- to their owner, so a student only ever receives their own cards. This adds
-- no visibility that the wallet query did not already have.
--
-- Idempotent: re-running is a no-op.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'digital_cards'
  ) then
    alter publication supabase_realtime add table public.digital_cards;
    raise notice 'realtime: added public.digital_cards to supabase_realtime';
  else
    raise notice 'realtime: public.digital_cards was already published';
  end if;
end $$;

-- An UPDATE event carries the old row only when the table replicates full
-- rows; the app only needs to know *that* something changed (it refetches via
-- `list_my_digital_cards`), so REPLICA IDENTITY is deliberately left alone.

-- Confirm what's published now:
--
--   select schemaname, tablename
--   from pg_publication_tables
--   where pubname = 'supabase_realtime'
--   order by tablename;
