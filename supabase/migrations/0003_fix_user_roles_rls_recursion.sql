-- Fix: "infinite recursion detected in policy for relation user_roles"
--
-- Cause: several RLS policies check "is this user an admin?" with an inline
-- `exists (select 1 from user_roles ...)`. Evaluating that subquery triggers
-- user_roles' OWN RLS policies, which themselves query user_roles -> Postgres
-- aborts the whole statement with a recursion error (42P17).
--
-- Because a `FOR ALL` policy's USING clause is evaluated on SELECT too, this
-- fired on every plain read of option_lists, making the profile pickers fail
-- with "Couldn't load options".
--
-- Remedy: do the role lookup inside a SECURITY DEFINER function. It runs as the
-- function owner, bypasses RLS on user_roles, and therefore cannot recurse.
-- Every policy then calls the function instead of reading user_roles directly.

-- 1. Recursion-free admin check ---------------------------------------------
create or replace function public.is_admin(uid uuid default auth.uid())
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.user_roles r
    where r.user_id = uid
      and r.role = 'admin'::app_role
  );
$$;

grant execute on function public.is_admin(uuid) to authenticated, anon;

-- 2. Rebuild option_lists policies on top of it -----------------------------
-- Drops both the pre-existing pair and the ones added in 0002; all four read
-- user_roles inline and so all four recurse.
drop policy if exists option_lists_admin_write          on public.option_lists;
drop policy if exists option_lists_write_admin          on public.option_lists;
drop policy if exists option_lists_select_active        on public.option_lists;
drop policy if exists option_lists_select_authenticated on public.option_lists;

-- Any signed-in user reads active options; admins additionally see inactive
-- ones (the admin panel toggles `active`).
create policy option_lists_select_authenticated
  on public.option_lists
  for select
  to authenticated
  using (active or public.is_admin());

-- Only admins may create/update/delete.
create policy option_lists_write_admin
  on public.option_lists
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());
