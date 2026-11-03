-- Blocking a user takes effect immediately, on the device and on the server.
--
-- Today an admin setting `profiles.banned_at` stops almost nothing. The app
-- already has the client half — `currentUserBanProvider` streams the viewer's
-- own profile row and `C2CApp` signs them out when `banned_at` appears — but:
--
--   1. `profiles` IS NOT IN THE `supabase_realtime` PUBLICATION. That stream
--      therefore connects, reports healthy, and never fires. Its one initial
--      SELECT is the only read it ever does, so a ban applied while the app is
--      open is invisible until the process is killed and relaunched — exactly
--      the reported behaviour. Same silent failure 0005, 0063, 0067 and 0073
--      each document for a different table.
--
--   2. NOTHING STOPS THE TOKEN. Even with the client logging itself out, the
--      access token in hand stays valid until it expires, and the refresh
--      token keeps minting new ones indefinitely. A blocked user who ignores
--      the client — or simply has an older build — keeps full API access, and
--      can sign in again freely. Client-side logout is a courtesy, not a
--      control.
--
-- Both are fixed here. The second is the one that matters.
--
-- HOW THE SERVER-SIDE HALF WORKS
--
-- Supabase Auth (GoTrue) already has a block mechanism: `auth.users.
-- banned_until`. While it is in the future GoTrue refuses to issue tokens and
-- refuses to refresh them, so a ban survives any client. Deleting the user's
-- rows in `auth.sessions` additionally kills the refresh tokens outstanding
-- right now, so the window shrinks from "until the refresh token expires" to
-- "until the current access token expires" — an hour at most, and in practice
-- the realtime logout closes it in seconds.
--
-- This is driven by a TRIGGER on `profiles.banned_at` rather than by editing
-- `admin_set_user_banned`. That function exists only in the live database (it
-- is in no migration in this repo), so re-declaring it here would mean
-- guessing a body I cannot read. A trigger needs no such guess and covers
-- every path that sets the column — the admin RPC, a console edit, a script.
--
-- Unbanning reverses it exactly: `banned_until` is cleared and the account
-- signs in normally again.
--
-- WHAT IS DELIBERATELY NOT TOUCHED
--
-- No chat, message, conversation or profile row is deleted, hidden or altered.
-- A blocked student simply stops being offered in discovery (0087) and stops
-- being able to authenticate. Every thread they were part of stays intact and
-- readable for the other participant, exactly as before.
--
-- Idempotent: re-running is a no-op.

-- ---------------------------------------------------------------------------
-- 1. Make the ban reach the open app
-- ---------------------------------------------------------------------------
-- The client subscribes with a server-side filter (`id=eq.<uid>`), so a device
-- only ever receives its own profile row — publishing the table does not fan
-- everyone's profile changes out to everyone.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
    raise notice 'realtime: added public.profiles to supabase_realtime';
  else
    raise notice 'realtime: public.profiles was already published';
  end if;
end $$;

-- `banned_at` has to be among the columns the client can SELECT for the
-- stream to carry it; it already is (`getMyProfile` reads it).

-- ---------------------------------------------------------------------------
-- 2. Make the ban stick server-side
-- ---------------------------------------------------------------------------
-- A far-future sentinel rather than a fixed span: the ban lasts until an admin
-- lifts it, and GoTrue only asks whether `banned_until` is in the future.
create or replace function public.sync_auth_ban_from_profile()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.banned_at is not distinct from old.banned_at then
    return new;
  end if;

  if to_regclass('auth.users') is null then
    raise warning 'sync_auth_ban_from_profile: auth.users not reachable; '
      'the ban is client-side only for %', new.id;
    return new;
  end if;

  if new.banned_at is not null then
    update auth.users
       set banned_until = timestamptz '2999-12-31 00:00:00+00'
     where id = new.id;

    -- Kill the refresh tokens outstanding right now. Without this the user
    -- keeps refreshing into fresh access tokens until the refresh token's own
    -- expiry, which can be weeks.
    if to_regclass('auth.sessions') is not null then
      delete from auth.sessions where user_id = new.id;
    end if;

    raise notice 'ban: auth access revoked for %', new.id;
  else
    update auth.users
       set banned_until = null
     where id = new.id;
    raise notice 'unban: auth access restored for %', new.id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_auth_ban_from_profile on public.profiles;
create trigger trg_sync_auth_ban_from_profile
  after update of banned_at on public.profiles
  for each row
  execute function public.sync_auth_ban_from_profile();

-- Reconcile anyone already blocked before this migration existed. Without it
-- the trigger only covers bans applied from now on, and the students blocked
-- yesterday would keep their tokens.
do $$
declare
  _reconciled int := 0;
begin
  if to_regclass('auth.users') is null then
    raise notice 'auth.users not reachable; skipping backfill';
    return;
  end if;

  update auth.users u
     set banned_until = timestamptz '2999-12-31 00:00:00+00'
    from public.profiles p
   where p.id = u.id
     and p.banned_at is not null
     and (u.banned_until is null or u.banned_until <= now());
  get diagnostics _reconciled = row_count;

  if to_regclass('auth.sessions') is not null then
    delete from auth.sessions s
     using public.profiles p
     where p.id = s.user_id
       and p.banned_at is not null;
  end if;

  raise notice 'backfill: revoked auth access for % already-blocked account(s)',
    _reconciled;
end $$;

-- ---------------------------------------------------------------------------
-- 3. A block outranks a deletion-cancellation
-- ---------------------------------------------------------------------------
-- `cancel_account_deletion` (0088) reactivates on sign-in by clearing
-- `deleted_at`. A blocked user cannot sign in once section 2 is in place, so
-- this is belt-and-braces — but the two features must not be able to combine
-- into a way around a block, and the rule belongs next to the thing it
-- protects rather than in a comment somewhere.
--
-- Body is 0088's, plus the ban check.
create or replace function public.cancel_account_deletion()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _me        uuid := auth.uid();
  _requested timestamptz;
  _banned    timestamptz;
begin
  if _me is null then
    return jsonb_build_object('status', 'not_signed_in');
  end if;

  select deletion_requested_at, banned_at
    into _requested, _banned
  from public.profiles
  where id = _me;

  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  -- New in 0089. An admin-imposed block is not something the account's owner
  -- may lift, and reactivating here would clear `deleted_at` on an account an
  -- admin has deliberately put out of use.
  if _banned is not null then
    return jsonb_build_object('status', 'blocked');
  end if;

  if _requested is null then
    return jsonb_build_object('status', 'ok', 'reactivated', false);
  end if;

  if _requested + interval '30 days' <= now() then
    return jsonb_build_object('status', 'expired', 'requested_at', _requested);
  end if;

  update public.profiles
     set deletion_requested_at = null,
         deleted_at            = null
   where id = _me;

  return jsonb_build_object('status', 'ok', 'reactivated', true);
end;
$$;

grant execute on function public.cancel_account_deletion() to authenticated;

-- Check the result:
--
--   select p.id, p.full_name, p.banned_at, u.banned_until
--   from public.profiles p
--   join auth.users u on u.id = p.id
--   where p.banned_at is not null;
--
-- `banned_until` in the future on every row = the block is enforced by Auth.
--
--   select schemaname, tablename from pg_publication_tables
--   where pubname = 'supabase_realtime' and tablename = 'profiles';
