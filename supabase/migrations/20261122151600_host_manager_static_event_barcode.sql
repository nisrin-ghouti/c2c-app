-- Let a host and a host-group manager print the permanent attendance barcode
-- for an event they already manage.
--
-- 0083 issued the three RPCs to admins only (`is_admin()`). The people who
-- run the event — its creator, a co-host, and the group manager of that
-- host — already pass `can_manage_event` (0062, widened in 0082) for edit,
-- attendance, and registration. Printing a poster is the same authority,
-- so these functions now use that check and nothing wider.
--
-- A manager still cannot print a code for an event outside their group, and
-- a host still cannot print one for an event they did not create and were
-- not added to. Scanning is unchanged: a static token is still just a row
-- in `event_qr_tokens`.

-- ---------------------------------------------------------------------------
-- 1. Generate / read / revoke
-- ---------------------------------------------------------------------------
create or replace function public.admin_create_static_event_qr(
  _event_id   uuid,
  _session_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  _token uuid;
begin
  -- Checked before the existence lookups so a caller who does not manage
  -- the event cannot probe which ids exist.
  if not public.can_manage_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if not exists (select 1 from public.events where id = _event_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  if _session_id is not null and not exists (
    select 1 from public.event_sessions
    where id = _session_id and event_id = _event_id
  ) then
    return jsonb_build_object('status', 'not_found');
  end if;

  select t.token into _token
  from public.event_qr_tokens t
  where t.event_id = _event_id
    and t.session_id is not distinct from _session_id
    and t.is_static
  limit 1;

  if _token is not null then
    return jsonb_build_object('status', 'ok', 'token', _token, 'created', false);
  end if;

  _token := gen_random_uuid();

  insert into public.event_qr_tokens (token, event_id, session_id, issued_at, expires_at, is_static)
  values (_token, _event_id, _session_id, now(), 'infinity'::timestamptz, true);

  return jsonb_build_object('status', 'ok', 'token', _token, 'created', true);
end;
$$;

revoke all on function public.admin_create_static_event_qr(uuid, uuid) from public;
grant execute on function public.admin_create_static_event_qr(uuid, uuid) to authenticated;

create or replace function public.admin_get_static_event_qr(
  _event_id   uuid,
  _session_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  _row public.event_qr_tokens%rowtype;
begin
  if not public.can_manage_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  select * into _row
  from public.event_qr_tokens
  where event_id = _event_id
    and session_id is not distinct from _session_id
    and is_static
  limit 1;

  if not found then
    return jsonb_build_object('status', 'none');
  end if;

  return jsonb_build_object(
    'status',    'ok',
    'token',     _row.token,
    'issued_at', _row.issued_at
  );
end;
$$;

revoke all on function public.admin_get_static_event_qr(uuid, uuid) from public;
grant execute on function public.admin_get_static_event_qr(uuid, uuid) to authenticated;

create or replace function public.admin_revoke_static_event_qr(
  _event_id   uuid,
  _session_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.can_manage_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  perform set_config('app.allow_static_qr_delete', 'on', true);

  delete from public.event_qr_tokens
  where event_id = _event_id
    and session_id is not distinct from _session_id
    and is_static;

  perform set_config('app.allow_static_qr_delete', 'off', true);

  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.admin_revoke_static_event_qr(uuid, uuid) from public;
grant execute on function public.admin_revoke_static_event_qr(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. A program's sessions, so a manager can pick which poster to print
-- ---------------------------------------------------------------------------
-- The group-events list does not open the event detail screen. A program
-- has no event-level barcode, so the print action loads `event_sessions`
-- directly. Creator and co-host policies already cover a host. A group
-- manager has no SELECT path onto a host's sessions, so the picker would
-- come back empty. `can_manage_event` is the same predicate the RPCs use.
drop policy if exists event_sessions_manage_select on public.event_sessions;
create policy event_sessions_manage_select
  on public.event_sessions
  for select
  to authenticated
  using (public.can_manage_event(event_id));
