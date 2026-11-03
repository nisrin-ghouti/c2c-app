-- The Register button on events has never worked: the Flutter client calls
-- `register_for_event`/`cancel_event_registration`, but neither RPC was ever
-- defined in any migration (confirmed via grep — every other event RPC has
-- one, these two don't). This is also why "My Events" always appeared empty
-- regardless of filter: event_registrations was never being written to, so
-- there was nothing to filter.

create or replace function public.register_for_event(_event_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _event public.events%rowtype;
  _registered_count int;
begin
  select * into _event from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'event_not_found');
  end if;

  if _event.approval_status <> 'approved' then
    return jsonb_build_object('status', 'not_published');
  end if;

  if now() > _event.ends_at then
    return jsonb_build_object('status', 'ended');
  end if;

  if exists (
    select 1 from public.event_registrations
    where event_id = _event_id and user_id = auth.uid() and status = 'registered'
  ) then
    return jsonb_build_object('status', 'already');
  end if;

  if _event.capacity is not null then
    select count(*) into _registered_count
    from public.event_registrations
    where event_id = _event_id and status = 'registered';

    if _registered_count >= _event.capacity then
      return jsonb_build_object('status', 'full');
    end if;
  end if;

  insert into public.event_registrations (event_id, user_id, status, registered_at)
  values (_event_id, auth.uid(), 'registered', now())
  on conflict (event_id, user_id)
  do update set status = 'registered', registered_at = now();

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.register_for_event(uuid) to authenticated;

create or replace function public.cancel_event_registration(_event_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _event public.events%rowtype;
begin
  select * into _event from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'not_registered');
  end if;

  if not exists (
    select 1 from public.event_registrations
    where event_id = _event_id and user_id = auth.uid() and status = 'registered'
  ) then
    return jsonb_build_object('status', 'not_registered');
  end if;

  -- Matches the mobile UI, which only shows the Cancel action while the
  -- event hasn't started yet (event_detail_screen.dart's `!event.hasStarted`
  -- guard) — enforced server-side too so a stale client can't bypass it.
  if now() > _event.starts_at then
    return jsonb_build_object('status', 'already_started');
  end if;

  update public.event_registrations
  set status = 'cancelled'
  where event_id = _event_id and user_id = auth.uid();

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.cancel_event_registration(uuid) to authenticated;
