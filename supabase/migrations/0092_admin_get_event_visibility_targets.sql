-- Admin/host read of an event's visibility targets (faculty / degree rows).
--
-- The admin console has called `admin_get_event_visibility_targets` for a
-- while (edit form prefill + event profile Visibility row), but the function
-- was never shipped. Without it the UI falls back to the generic
-- "Specific Faculties" label and the edit form cannot restore chips.
--
-- Gated on `can_manage_event` so admins, the event host/co-host, and host
-- group managers can all read the same rows they are already allowed to
-- write via `update_event_or_program`.

create or replace function public.admin_get_event_visibility_targets(
  _event_id uuid
)
returns table (
  target_type text,
  target_value text
)
language plpgsql
stable
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null
     or not public.can_manage_event(_event_id, auth.uid()) then
    return;
  end if;

  return query
  select t.target_type, t.target_value
  from public.event_visibility_targets t
  where t.event_id = _event_id
  order by t.target_type, t.target_value;
end;
$$;

grant execute on function public.admin_get_event_visibility_targets(uuid)
  to authenticated;
