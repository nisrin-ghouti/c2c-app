-- Why can't this user be blocked from the admin console's user list?
--
-- The console calls `admin_set_user_banned(_user_id, _banned, _reason)`. That
-- function is NOT defined in any migration in this repo — like
-- `admin_update_profile` was before 0051, it exists only in the live
-- database — so the only way to see its rules is to read it from there.
--
-- A probe with a bogus id returns `{"code":"P0001","message":"User not found"}`,
-- i.e. the function RAISES rather than returning `{"status": "..."}`. That
-- matters: the console maps returned statuses to friendly messages
-- ('forbidden' -> "not allowed"), but a raise arrives as a raw
-- PostgrestException and surfaces as a generic error. So "it doesn't work"
-- can be a deliberate refusal wearing the wrong clothes.
--
-- Read-only. One result set.

-- Replace the email, then run the whole file.
with target as (
  select id, full_name, email, is_super_admin, banned_at
  from public.profiles
  where lower(email) = lower('REPLACE_WITH_EMAIL')
),
who as (
  select
    'A. target found?' as check_name,
    case when exists (select 1 from target) then 'YES' else 'NO — check the email' end as value,
    coalesce((select full_name || ' / ' || coalesce(email,'(no email)') from target), '') as note
),
super as (
  select
    'B. is SUPER ADMIN?' as check_name,
    coalesce((select case when coalesce(is_super_admin,false) then 'YES' else 'no' end from target), '?') as value,
    'If YES this is the answer: migration 0011 protects this account by spec — '
      'it cannot be deleted and its admin role cannot be removed. Whether that '
      'guard also blocks banning depends on the function body (see E).' as note
),
already as (
  select
    'C. already banned?' as check_name,
    coalesce((select case when banned_at is null then 'no' else 'YES, since ' || banned_at::text end from target), '?') as value,
    'If already banned, the console may simply be showing no visible change.' as note
),
roles as (
  select
    'D. roles held' as check_name,
    coalesce((select string_agg(r.role::text, ', ')
              from public.user_roles r join target t on t.id = r.user_id), '(none)') as value,
    'Many ban implementations refuse to ban an admin outright.' as note
),
fn as (
  select
    'E. function source' as check_name,
    coalesce((
      select p.oid::regprocedure::text
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname = 'admin_set_user_banned'
      limit 1
    ), 'NOT INSTALLED') as value,
    coalesce((
      -- The refusal conditions, pulled straight out of the body.
      select string_agg(trim(line), ' | ')
      from (
        select unnest(string_to_array(pg_get_functiondef(p.oid), e'\n')) as line
        from pg_proc p join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public' and p.proname = 'admin_set_user_banned'
        limit 1
      ) lines
      where line ilike '%raise exception%'
         or line ilike '%forbidden%'
         or line ilike '%super_admin%'
         or line ilike '%is_admin%'
    ), '(no guard lines found — see the full body below)') as note
),
caller as (
  select
    'F. are YOU an admin?' as check_name,
    case when public.is_admin(auth.uid()) then 'YES' else 'no / not signed in' end as value,
    'In the SQL editor auth.uid() is usually null, so "no" here is expected '
      'and means nothing. It matters only if the CONSOLE is what returns '
      'forbidden.' as note
)
select * from who
union all select * from super
union all select * from already
union all select * from roles
union all select * from fn
union all select * from caller;

-- If E did not make the rule obvious, read the whole function:
--
--   select pg_get_functiondef(p.oid)
--   from pg_proc p join pg_namespace n on n.oid = p.pronamespace
--   where n.nspname = 'public' and p.proname = 'admin_set_user_banned';
--
-- And if the answer turns out to be "an admin cannot be banned", the
-- supported path is to remove their admin role FIRST and then ban them:
--
--   delete from public.user_roles
--   where user_id = (select id from public.profiles
--                    where lower(email) = lower('REPLACE_WITH_EMAIL'))
--     and role = 'admin'::app_role;
--
-- (That will itself raise if they are the super admin — guarded by 0011's
-- protect_super_admin_roles trigger.)
