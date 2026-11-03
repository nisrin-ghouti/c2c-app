-- Fix: "Show my QR" fails with
--   function gen_random_bytes(integer) does not exist  (SQLSTATE 42883)
--
-- create_meeting_session() mints its QR token with gen_random_bytes(), which
-- is provided by the pgcrypto EXTENSION — not by Postgres core. (gen_random_uuid()
-- IS core since PG13, which is why other inserts work fine.) pgcrypto was never
-- enabled on this project, so the RPC throws and the host screen falls straight
-- through to its error state, never rendering a QR.
--
-- Any other RPC that mints a random token the same way is broken identically —
-- likely the event QR tokens, group-meeting join links, and benefit/digital
-- card codes. Enabling the extension fixes all of them at once.
--
-- Installed into the `extensions` schema, which is Supabase's convention (it
-- keeps `public` clean and is already on the default search_path).
--
-- Idempotent: safe to re-run.

create schema if not exists extensions;

create extension if not exists pgcrypto with schema extensions;

grant usage on schema extensions to authenticated, anon, service_role;

-- Verify the function now resolves:
--
--   select length(extensions.gen_random_bytes(16));   -- expect 16
--
-- If "Show my QR" STILL reports the same error after this, the RPC itself is
-- pinned to a search_path that excludes `extensions`. Check with:
--
--   select p.proname, p.proconfig, p.prosecdef
--   from pg_proc p
--   join pg_namespace n on n.oid = p.pronamespace
--   where n.nspname = 'public' and p.proname = 'create_meeting_session';
--
-- If proconfig shows something like {search_path=public}, the function must
-- either call extensions.gen_random_bytes(...) explicitly, or be redefined with
--   set search_path = public, extensions
