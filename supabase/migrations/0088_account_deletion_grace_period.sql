-- Account deletion becomes a 30-day deactivation that logging back in cancels.
--
-- Today `delete-account` is immediate and total: it calls
-- `purge_user_account` (0058) and then removes the auth user. There is no
-- undo, and a student who taps it by mistake — or changes their mind an hour
-- later — has lost the account. App Store Guideline 5.1.1(v) requires that
-- deletion be *offered*, not that it be instantaneous, so a grace period is
-- compatible with it.
--
-- The new shape:
--
--   request  -> `profiles.deletion_requested_at = now()`, account deactivated
--   sign in  -> the column is cleared, the account is live again
--   30 days  -> a scheduled sweep purges it for real, exactly as before
--
-- WHAT "DEACTIVATED" MEANS, and why it reuses `deleted_at`.
--
-- `deleted_at` is already the app's soft-delete marker and is already filtered
-- out of every discovery surface, the notification fan-outs, and the new
-- `is_discoverable_student` (0087). Setting it alongside
-- `deletion_requested_at` therefore makes an account pending deletion
-- disappear from other students for free, through paths that already exist
-- and are already tested. Introducing a second, parallel "inactive" flag would
-- mean auditing all of those again and would leave two things to keep in sync.
--
-- So: `deletion_requested_at` is the clock, `deleted_at` is the state. The
-- pair is set and cleared together, always, by the two functions below.
--
-- THE DATA IS NOT TOUCHED DURING THE GRACE PERIOD. Nothing is anonymised,
-- severed or deleted until the sweep runs — that is the entire point, since a
-- cancellation has to restore a working account, not an empty shell. The
-- irreversible work still happens exactly once, in `purge_user_account`,
-- unchanged.
--
--   >>> SHIPS WITH THE `delete-account` EDGE FUNCTION. <<<
--
-- That function currently purges immediately. Until it is redeployed to call
-- `request_account_deletion()` instead, this migration changes nothing about
-- what a deletion does — it only adds the mechanism. Deploy both together.
--
-- Idempotent: re-running replaces the functions and re-adds nothing.

-- ---------------------------------------------------------------------------
-- 1. The clock
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists deletion_requested_at timestamptz;

comment on column public.profiles.deletion_requested_at is
  'When the user asked for their account to be deleted. Non-null means the '
  'account is deactivated and will be purged 30 days later unless they sign '
  'in first, which clears this and deleted_at together. Null is the normal '
  'state for a live account.';

-- Finding the due accounts is a scan over a tiny subset, so the index is
-- partial — it stays empty in the normal case where nobody is pending.
create index if not exists profiles_deletion_requested_idx
  on public.profiles (deletion_requested_at)
  where deletion_requested_at is not null;

-- ---------------------------------------------------------------------------
-- 2. Request — what the edge function calls instead of purging
-- ---------------------------------------------------------------------------
-- Returns the deadline so the client can tell the user exactly how long they
-- have to change their mind.
create or replace function public.request_account_deletion(_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _requested_at timestamptz := now();
  _existing     timestamptz;
begin
  if _user_id is null then
    raise exception 'request_account_deletion: _user_id is required';
  end if;

  select deletion_requested_at into _existing
  from public.profiles
  where id = _user_id;

  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  -- Asking twice must not extend the deadline — otherwise a user repeatedly
  -- tapping delete would push their own purge date further out each time.
  if _existing is not null then
    return jsonb_build_object(
      'status',       'ok',
      'requested_at', _existing,
      'purge_after',  _existing + interval '30 days',
      'unchanged',    true
    );
  end if;

  update public.profiles
     set deletion_requested_at = _requested_at,
         -- The deactivation itself. Reuses the existing soft-delete marker so
         -- every surface that already excludes deleted profiles excludes this
         -- account too, with no new filtering anywhere.
         deleted_at            = _requested_at
   where id = _user_id;

  return jsonb_build_object(
    'status',       'ok',
    'requested_at', _requested_at,
    'purge_after',  _requested_at + interval '30 days'
  );
end;
$$;

revoke all on function public.request_account_deletion(uuid) from public;
revoke all on function public.request_account_deletion(uuid) from anon;
revoke all on function public.request_account_deletion(uuid) from authenticated;
grant execute on function public.request_account_deletion(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- 3. Cancel — called by the app on every successful sign-in
-- ---------------------------------------------------------------------------
-- Deliberately callable by the signed-in user for THEMSELVES only: it reads
-- `auth.uid()` and takes no argument, so it cannot be aimed at anyone else.
-- A no-op for an account that was never pending, so the app can call it
-- unconditionally after sign-in without first asking whether it is needed.
create or replace function public.cancel_account_deletion()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _me        uuid := auth.uid();
  _requested timestamptz;
begin
  if _me is null then
    return jsonb_build_object('status', 'not_signed_in');
  end if;

  select deletion_requested_at into _requested
  from public.profiles
  where id = _me;

  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  if _requested is null then
    return jsonb_build_object('status', 'ok', 'reactivated', false);
  end if;

  -- Past the deadline the account is already owed a purge. Reactivating it
  -- here would resurrect an account the sweep is about to remove, so refuse
  -- and let the sweep do its job. In practice this is nearly unreachable —
  -- sign-in is blocked once the auth user is gone — but the window between
  -- "deadline passed" and "sweep ran" is real, and it should not be the one
  -- moment a deletion can be undone by accident.
  if _requested + interval '30 days' <= now() then
    return jsonb_build_object('status', 'expired', 'requested_at', _requested);
  end if;

  update public.profiles
     set deletion_requested_at = null,
         deleted_at            = null
   where id = _me;

  return jsonb_build_object(
    'status',      'ok',
    'reactivated', true
  );
end;
$$;

grant execute on function public.cancel_account_deletion() to authenticated;

-- ---------------------------------------------------------------------------
-- 4. The sweep
-- ---------------------------------------------------------------------------
-- Purges accounts whose 30 days have elapsed, reusing `purge_user_account`
-- unchanged — the same SET NULL / DELETE policy per foreign key that the
-- immediate path used, so nothing about what survives a deletion changes.
--
-- NOTE: this clears the `public` schema only. The matching `auth.users` row is
-- removed by the Edge Function in the immediate path and must be removed here
-- too; plain SQL cannot call the Auth admin API, so the companion scheduled
-- function does it. Until that runs, a purged account leaves a sign-in-capable
-- auth row with no profile — which `ensureProfileExists` would hand a blank
-- profile. Section 5 covers this.
create or replace function public.purge_expired_deleted_accounts()
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _user_id uuid;
  _purged  integer := 0;
begin
  for _user_id in
    select id
    from public.profiles
    where deletion_requested_at is not null
      and deletion_requested_at + interval '30 days' <= now()
    -- A bounded batch: one stuck account must not block the rest, and a long
    -- transaction holding locks across every table purge_user_account touches
    -- is worth avoiding. The job runs daily, so the backlog drains quickly.
    limit 100
  loop
    begin
      perform public.purge_user_account(_user_id);
      _purged := _purged + 1;
    exception when others then
      -- Never let one account's failure abort the sweep.
      raise warning 'purge_expired_deleted_accounts: % failed (%): %',
        _user_id, sqlstate, sqlerrm;
    end;
  end loop;

  return _purged;
end;
$$;

revoke all on function public.purge_expired_deleted_accounts() from public;
revoke all on function public.purge_expired_deleted_accounts() from anon;
revoke all on function public.purge_expired_deleted_accounts() from authenticated;
grant execute on function public.purge_expired_deleted_accounts() to service_role;

-- ---------------------------------------------------------------------------
-- 5. Scheduling
-- ---------------------------------------------------------------------------
-- Daily at 03:00 campus time. A deletion owed at 30 days is purged within 24
-- hours of becoming due, which is the right granularity for a 30-day promise.
--
-- 03:00 Asia/Jerusalem is 00:00 or 01:00 UTC depending on DST; pg_cron runs in
-- UTC, so this is pinned to 01:00 UTC rather than drifting an hour twice a
-- year. The exact hour does not matter — only that it is quiet and daily.
--
-- The auth.users half cannot be done from SQL. Either:
--   * run the `purge-expired-accounts` Edge Function on a schedule instead of
--     this job (it calls this function and then deletes the auth users), or
--   * keep this job and let the next `delete-account` invocation reconcile.
-- The first is what ships; this job is the fallback so the data is cleared on
-- time even if the function is not scheduled.
do $$
begin
  begin
    create extension if not exists pg_cron;
  exception when others then
    raise notice
      'pg_cron not available (%). Schedule purge_expired_deleted_accounts() '
      'some other way.', sqlerrm;
    return;
  end;

  perform cron.schedule(
    'purge-expired-deleted-accounts',
    '0 1 * * *',
    'select public.purge_expired_deleted_accounts();'
  );
  raise notice 'cron: purge-expired-deleted-accounts scheduled daily at 01:00 UTC';
exception when others then
  raise notice 'could not schedule the purge sweep (%)', sqlerrm;
end $$;

-- Who is currently pending, and when they are due:
--
--   select id, full_name, email, deletion_requested_at,
--          deletion_requested_at + interval '30 days' as purge_after,
--          deletion_requested_at + interval '30 days' <= now() as overdue
--   from public.profiles
--   where deletion_requested_at is not null
--   order by deletion_requested_at;
