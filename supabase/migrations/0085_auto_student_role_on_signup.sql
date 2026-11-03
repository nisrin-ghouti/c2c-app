-- Every self-registration gets the Student role automatically.
--
-- The mobile app's sign-up is a plain `auth.signUp` with `{full_name}` and
-- nothing else — it never writes to `user_roles`. So a user who registers
-- through the app has *no* role at all until an admin notices and grants one,
-- which is the gap this closes.
--
-- Doing it in a trigger rather than in the client is what makes it
-- unforgeable. `user_roles` is admin-write-only under RLS (0004), so the app
-- could not insert its own role even if it tried; a `security definer` trigger
-- is the only thing that can, and it decides the role rather than accepting
-- one from the caller. There is no code path by which a registrant chooses
-- what they become.
--
-- THE HARD PART: not catching console-created accounts.
--
-- `admin-create-user` deliberately grants exactly the roles an admin picked,
-- with no implicit Student baseline — an Admin-only or Host-only account is a
-- supported thing, and such accounts are excluded from matching, points and
-- benefits server-side. A blanket trigger would quietly add Student to every
-- one of them and undo that.
--
-- Auth gives the trigger nothing to distinguish the two paths by: both arrive
-- as an INSERT into `auth.users` carrying `{full_name}`. So the edge function
-- now stamps `created_by_console: true` into user metadata, and this trigger
-- skips any row carrying it.
--
--   >>> THIS MIGRATION AND THE EDGE FUNCTION MUST SHIP TOGETHER. <<<
--
-- Until `admin-create-user` is redeployed, accounts created from the admin
-- panel will also receive Student. That is additive and reversible (untick it
-- in the roles sheet), not destructive — but it is a behaviour change, so run
-- this one last and redeploy the function at the same time.

-- ---------------------------------------------------------------------------
-- 1. The trigger
-- ---------------------------------------------------------------------------
create or replace function public.assign_student_role_on_signup()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  -- Created by an admin or a host group manager through the console, which
  -- chooses roles explicitly. Leave it alone.
  if coalesce(
       (new.raw_user_meta_data ->> 'created_by_console')::boolean,
       false
     )
  then
    return new;
  end if;

  -- `on conflict do nothing` rather than a prior existence check: the unique
  -- constraint on (user_id, role) is the real guard, and this way a replayed
  -- or concurrent insert is a no-op instead of an error that would fail the
  -- whole sign-up.
  insert into public.user_roles (user_id, role)
  values (new.id, 'student'::app_role)
  on conflict (user_id, role) do nothing;

  return new;
end;
$$;

-- AFTER INSERT, so a failure here cannot roll back the account creation
-- itself. A user who somehow ends up without the role can be granted it from
-- the admin panel; a user who cannot register at all is a much worse outcome.
drop trigger if exists trg_assign_student_role_on_signup on auth.users;
create trigger trg_assign_student_role_on_signup
  after insert on auth.users
  for each row
  execute function public.assign_student_role_on_signup();

-- ---------------------------------------------------------------------------
-- 2. Backfill
-- ---------------------------------------------------------------------------
-- Users who already registered through the app and have no role at all. They
-- are the population this trigger exists for, just earlier.
--
-- Scoped to accounts with ZERO roles on purpose. An existing Host-only or
-- Admin-only account is intentional and must not have Student bolted on, and
-- "has no roles whatsoever" is the only signal available for telling a
-- stranded registrant apart from a deliberate one.
insert into public.user_roles (user_id, role)
select u.id, 'student'::app_role
from auth.users u
where not exists (
  select 1 from public.user_roles r where r.user_id = u.id
)
on conflict (user_id, role) do nothing;

-- ---------------------------------------------------------------------------
-- 3. Report
-- ---------------------------------------------------------------------------
do $$
declare
  _backfilled int;
  _roleless   int;
begin
  select count(*) into _roleless
  from auth.users u
  where not exists (select 1 from public.user_roles r where r.user_id = u.id);

  select count(*) into _backfilled
  from public.user_roles where role = 'student'::app_role;

  raise notice 'Accounts holding Student: %', _backfilled;
  raise notice 'Accounts still with no role at all: % (expected 0)', _roleless;
  raise notice 'REMINDER: redeploy admin-create-user, or console-created accounts will also get Student.';
end $$;
