-- Editing an already-approved event used to silently send it back to
-- 'pending' (and drop it off the student-facing list) until an admin
-- re-approved it — including for fixes as small as correcting a
-- translation. Per product decision, an admin's own edit now stays live
-- immediately with no re-review step; a host's edit (even to their own
-- event) still goes back to pending, same as before, since hosts aren't
-- trusted to self-approve.
-- Re-create update_event_or_program (body verbatim from
-- 0055_add_english_translation_slot.sql) with the approval_status/
-- rejection_reason reset made conditional on the caller not being an admin.
create or replace function public.update_event_or_program(_event_id uuid, _event jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  _row public.events%rowtype;
  _is_admin boolean;
  _can_manage boolean;
begin
  select * into _row from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  select exists(select 1 from public.user_roles where user_id = auth.uid() and role = 'admin')
  into _is_admin;

  select
    _is_admin
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
    title_ar = nullif(_event->>'title_ar', ''),
    title_he = nullif(_event->>'title_he', ''),
    description_ar = nullif(_event->>'description_ar', ''),
    description_he = nullif(_event->>'description_he', ''),
    location_ar = nullif(_event->>'location_ar', ''),
    location_he = nullif(_event->>'location_he', ''),
    organizer_name_ar = nullif(_event->>'organizer_name_ar', ''),
    organizer_name_he = nullif(_event->>'organizer_name_he', ''),
    organizer_description_ar = nullif(_event->>'organizer_description_ar', ''),
    organizer_description_he = nullif(_event->>'organizer_description_he', ''),
    title_en = nullif(_event->>'title_en', ''),
    description_en = nullif(_event->>'description_en', ''),
    location_en = nullif(_event->>'location_en', ''),
    organizer_name_en = nullif(_event->>'organizer_name_en', ''),
    organizer_description_en = nullif(_event->>'organizer_description_en', ''),
    -- Admin edits stay approved with no re-review. A host's edit still
    -- resets an already-approved event back to pending, exactly like before.
    approval_status = case
      when _is_admin then approval_status
      when approval_status = 'approved' then 'pending'
      else approval_status
    end,
    rejection_reason = case
      when _is_admin then rejection_reason
      when approval_status = 'approved' then null
      else rejection_reason
    end
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
