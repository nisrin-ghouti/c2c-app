-- Wire the Event Profile columns (added in 0013) into the create/update RPCs.
-- Without this, create_event_or_program / update_event_or_program insert only
-- the original columns, so organizer_description and external_link silently
-- save as null even though the form sends them.
--
-- Bodies are the existing functions verbatim (same host/admin checks, same
-- session + visibility_targets logic, same return shape) with only the two new
-- columns added to the insert and the update.

create or replace function public.create_event_or_program(_event jsonb, _sessions jsonb default null::jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  _new_id uuid;
  _can_create boolean;
begin
  select exists(
    select 1 from public.user_roles where user_id = auth.uid() and role in ('host','admin')
  ) into _can_create;

  if not _can_create then
    return jsonb_build_object('status', 'forbidden');
  end if;

  insert into public.events (
    title, description, category, location, starts_at, ends_at, points,
    image_url, organizer_name, organizer_description, external_link,
    created_by, event_kind, approval_status, visibility, capacity
  ) values (
    _event->>'title',
    nullif(_event->>'description', ''),
    nullif(_event->>'category', ''),
    nullif(_event->>'location', ''),
    (_event->>'starts_at')::timestamptz,
    (_event->>'ends_at')::timestamptz,
    coalesce((_event->>'points')::int, 20),
    nullif(_event->>'image_url', ''),
    nullif(_event->>'organizer_name', ''),
    nullif(_event->>'organizer_description', ''),
    nullif(_event->>'external_link', ''),
    auth.uid(),
    coalesce(_event->>'event_kind', 'single'),
    'pending',
    coalesce(_event->>'visibility', 'everyone'),
    nullif(_event->>'capacity', '')::int
  )
  returning id into _new_id;

  if _event ? 'visibility_targets' then
    insert into public.event_visibility_targets (event_id, target_type, target_value)
    select _new_id, t->>'target_type', t->>'target_value'
    from jsonb_array_elements(_event->'visibility_targets') as t;
  end if;

  if _sessions is not null then
    insert into public.event_sessions (event_id, title, starts_at, ends_at, location)
    select _new_id, s->>'title', (s->>'starts_at')::timestamptz, (s->>'ends_at')::timestamptz, nullif(s->>'location','')
    from jsonb_array_elements(_sessions) as s;
  end if;

  return jsonb_build_object('status', 'ok', 'id', _new_id);
end;
$function$;

create or replace function public.update_event_or_program(_event_id uuid, _event jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  _row public.events%rowtype;
  _can_manage boolean;
begin
  select * into _row from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  select
    exists(select 1 from public.user_roles where user_id = auth.uid() and role = 'admin')
    or (
      exists(select 1 from public.user_roles where user_id = auth.uid() and role = 'host')
      and (
        _row.created_by = auth.uid()
        or exists(select 1 from public.host_event_access h where h.event_id = _event_id and h.host_user_id = auth.uid())
      )
    )
  into _can_manage;

  if not _can_manage then
    return jsonb_build_object('status', 'forbidden');
  end if;

  update public.events set
    title = coalesce(_event->>'title', title),
    description = nullif(_event->>'description', ''),
    category = nullif(_event->>'category', ''),
    location = nullif(_event->>'location', ''),
    starts_at = coalesce((_event->>'starts_at')::timestamptz, starts_at),
    ends_at = coalesce((_event->>'ends_at')::timestamptz, ends_at),
    points = coalesce((_event->>'points')::int, points),
    image_url = nullif(_event->>'image_url', ''),
    organizer_name = nullif(_event->>'organizer_name', ''),
    organizer_description = nullif(_event->>'organizer_description', ''),
    external_link = nullif(_event->>'external_link', ''),
    visibility = coalesce(_event->>'visibility', visibility),
    capacity = nullif(_event->>'capacity', '')::int,
    -- editing an already-approved event sends it back for re-review
    approval_status = case when approval_status = 'approved' then 'pending' else approval_status end,
    rejection_reason = case when approval_status = 'approved' then null else rejection_reason end
  where id = _event_id;

  delete from public.event_visibility_targets where event_id = _event_id;
  if _event ? 'visibility_targets' then
    insert into public.event_visibility_targets (event_id, target_type, target_value)
    select _event_id, t->>'target_type', t->>'target_value'
    from jsonb_array_elements(_event->'visibility_targets') as t;
  end if;

  return jsonb_build_object('status', 'ok');
end;
$function$;
