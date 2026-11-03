-- Lets a host group manager edit their group's events.
--
-- 0081 gave the role view, approve and attendance over its hosts' events but
-- deliberately not edit, because `can_manage_event` backs RLS policies and
-- widening it would have granted more than was asked for. Edit is now wanted,
-- so this does two separate things rather than one blunt one:
--
--   1. Widens `can_manage_event` to include the group predicate. That is what
--      the registration switch, accepted-participants, session-attendance and
--      event-hosts reads all gate on, so a manager now reaches those for their
--      group's events too — the natural meaning of "can manage this event".
--
--   2. Redeclares `update_event_or_program`, because it does NOT call
--      `can_manage_event`: it inlines its own admin/host/co-host check, so
--      step 1 alone would not have let a manager save a single edit. The body
--      below is 0057's verbatim with three changes, all marked.
--
-- Depends on 0081. Run after it.
--
-- One consequence worth stating: whether this also grants DELETE depends on
-- the `events` delete policy, which predates the migration series and lives
-- only in the live database. If that policy is written in terms of
-- `can_manage_event`, managers can now delete their group's events as well as
-- edit them. The reporting block at the end prints it so you can see which.

-- ---------------------------------------------------------------------------
-- 1. `can_manage_event` now covers a manager's group
-- ---------------------------------------------------------------------------
-- 0062's body, plus the group disjunct.
create or replace function public.can_manage_event(
  _event_id uuid,
  _user_id  uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    public.is_admin(_user_id)
    or public.group_manager_can_act_on_event(_event_id, _user_id)
    or (
      exists (
        select 1 from public.user_roles
        where user_id = _user_id and role = 'host'
      )
      and (
        exists (
          select 1 from public.events e
          where e.id = _event_id and e.created_by = _user_id
        )
        or public.has_event_host_access(_event_id, _user_id)
      )
    );
$$;

-- ---------------------------------------------------------------------------
-- 2. Editing
-- ---------------------------------------------------------------------------
create or replace function public.update_event_or_program(_event_id uuid, _event jsonb, _sessions jsonb default null::jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  _row public.events%rowtype;
  _is_admin boolean;
  _is_group_manager boolean;
  _can_manage boolean;
begin
  select * into _row from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  select exists(select 1 from public.user_roles where user_id = auth.uid() and role = 'admin')
  into _is_admin;

  -- New in 0082: a host group manager may edit events authored by hosts in
  -- their group, and their own. `group_manager_can_act_on_event` (0081) is
  -- the same predicate that already governs approving and attendance, so
  -- editing cannot reach an event the manager could not already act on.
  _is_group_manager := public.group_manager_can_act_on_event(_event_id);

  select
    _is_admin
    or _is_group_manager
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
    -- A group manager is the approver for their own group, so sending their
    -- edit back to `pending` would only ask them to re-approve their own
    -- change. Treated like an admin here for that reason. A *host* editing
    -- the same event still drops it to pending, unchanged, and the manager
    -- reviews it — which is the behaviour this role exists to provide.
    approval_status = case
      when _is_admin or _is_group_manager then approval_status
      when approval_status = 'approved' then 'pending'
      else approval_status
    end,
    rejection_reason = case
      when _is_admin or _is_group_manager then rejection_reason
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

  if _sessions is not null then
    delete from public.event_sessions where event_id = _event_id;
    insert into public.event_sessions (event_id, title, starts_at, ends_at, location)
    select _event_id, s->>'title', (s->>'starts_at')::timestamptz, (s->>'ends_at')::timestamptz, nullif(s->>'location','')
    from jsonb_array_elements(_sessions) as s;
  end if;

  return jsonb_build_object('status', 'ok');
end;
$function$;

-- ---------------------------------------------------------------------------
-- 3. What the events DELETE policy actually gates on
-- ---------------------------------------------------------------------------
-- Printed, not changed. If any of these mention `can_manage_event`, step 1
-- just widened deletion to group managers as well as editing. If they name
-- `created_by` or `has_event_host_access` instead, deletion is unaffected.
do $$
declare
  _p record;
  _found boolean := false;
begin
  raise notice 'DELETE policies on public.events:';
  for _p in
    select policyname, qual
    from pg_policies
    where schemaname = 'public' and tablename = 'events'
      and cmd in ('DELETE', 'ALL')
  loop
    _found := true;
    raise notice '  % using=%', _p.policyname, _p.qual;
  end loop;

  if not _found then
    raise notice '  (none found)';
  end if;
end $$;
