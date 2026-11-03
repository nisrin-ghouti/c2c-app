-- Students can now delete their own notifications (single, multi-select, or
-- "clear all") from the app — only a SELECT and an UPDATE (mark read) RLS
-- policy existed on `notifications` before this, so a delete from the
-- client was silently rejected by RLS.
create policy "users delete own notifications"
  on public.notifications
  for delete
  using (user_id = auth.uid());
