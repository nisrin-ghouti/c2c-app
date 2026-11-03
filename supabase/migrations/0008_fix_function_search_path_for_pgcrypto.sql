-- Follow-up to 0007. Enabling pgcrypto wasn't enough on its own.
--
-- create_meeting_session() is SECURITY DEFINER with its search_path pinned:
--
--   proname                 proconfig                  prosecdef
--   create_meeting_session  ["search_path=public"]     true
--
-- Pinning search_path on a SECURITY DEFINER function is correct practice (it
-- stops a caller from shadowing objects the elevated function resolves), but
-- `public` alone excludes the `extensions` schema where pgcrypto lives — so
-- gen_random_bytes() still doesn't resolve and the RPC keeps throwing 42883.
--
-- Fix: widen the pin to `public, extensions`. ALTER FUNCTION changes only the
-- setting, leaving each function body untouched, and keeps the hardening.
--
-- Applies to EVERY function in `public` that mints tokens with gen_random_bytes
-- (meeting QR sessions, event QR tokens, group-meeting join links, card codes),
-- since they all share this failure.
--
-- Requires 0007 (which installs pgcrypto into `extensions`) to have run first.
-- Idempotent: safe to re-run.

do $$
declare
  fn record;
begin
  for fn in
    select p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosrc like '%gen_random_bytes%'
  loop
    execute format('alter function %s set search_path = public, extensions', fn.signature);
    raise notice 'search_path widened for %', fn.signature;
  end loop;
end $$;

-- Confirm every affected function now resolves pgcrypto:
--
--   select p.oid::regprocedure as function, p.proconfig
--   from pg_proc p
--   join pg_namespace n on n.oid = p.pronamespace
--   where n.nspname = 'public' and p.prosrc like '%gen_random_bytes%';
--
-- Each proconfig should now read {"search_path=public, extensions"}.
