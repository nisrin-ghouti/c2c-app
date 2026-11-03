-- Fix the RLS recursion at its SOURCE: user_roles' own policies.
--
-- Two policies ON user_roles answered "is this user an admin?" by querying
-- user_roles, which re-triggers those same policies -> Postgres aborts with
-- "infinite recursion detected in policy for relation user_roles" (42P17):
--
--   user_roles_admin_write         ALL     EXISTS (SELECT 1 FROM user_roles r ...)
--   user_roles_select_own_or_admin SELECT  user_id = auth.uid() OR EXISTS (... user_roles ...)
--
-- This broke far more than the profile pickers: every table whose policies
-- check admin via a `FROM user_roles` subquery inherited the recursion —
-- benefits, digital_cards, event_attendance, event_registrations,
-- event_visibility_targets, group_meeting_links, group_meeting_registrations,
-- group_meetings, host_event_access — plus the app's own role lookup.
--
-- Fix: route the admin check through public.is_admin() (created in 0003). It's
-- SECURITY DEFINER, so it runs as the function owner and bypasses RLS on
-- user_roles — it therefore cannot recurse. Repointing these two policies at it
-- unblocks every dependent table at once, with no change to their policies.
--
-- Requires 0003 (which creates public.is_admin) to have run first.

drop policy if exists user_roles_admin_write         on public.user_roles;
drop policy if exists user_roles_select_own_or_admin on public.user_roles;

-- A user may read their own roles; admins may read everyone's.
create policy user_roles_select_own_or_admin
  on public.user_roles
  for select
  to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- Only admins may grant/revoke roles.
create policy user_roles_admin_write
  on public.user_roles
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- NOTE: the pre-existing "users see own roles" (SELECT, authenticated,
-- user_id = auth.uid()) policy is now redundant — it's a subset of
-- user_roles_select_own_or_admin above — but it's harmless and non-recursive,
-- so it's left alone rather than risk changing behaviour you rely on.
