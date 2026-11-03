-- Fix: students never saw `specific_faculties` events that matched
-- `profiles.faculties[]` but not the legacy single `profiles.faculty`.
--
-- Root cause: the pre-migration permissive policy
-- `authenticated view published events` re-implemented faculty targeting as
-- `t.target_value = p.faculty` only. Migration 0069 added the correct check
-- in `event_is_visible_to` (faculties[] OR faculty, plus degree AND) behind a
-- RESTRICTIVE policy — but permissive policies must still GRANT the row, and
-- this one kept denying whenever the match was only in the array.
--
-- Example that failed: event target "Management", student
-- faculties = {Social Sciences, Management}, faculty = 'Social Sciences'.
-- `event_is_visible_to` → true; this permissive policy → false → hidden.
--
-- Fix: permissive policy only decides "is this a published event the role may
-- consider" (approved / own / admin). Visibility narrowing stays entirely in
-- `events_visibility_restrictive` → `event_is_visible_to`.

drop policy if exists "authenticated view published events" on public.events;

create policy "authenticated view published events"
  on public.events
  as permissive
  for select
  to public
  using (
    (approval_status = 'approved')
    or (created_by = auth.uid())
    or public.has_role(auth.uid(), 'admin'::public.app_role)
  );
