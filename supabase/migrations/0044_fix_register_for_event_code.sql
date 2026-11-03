-- `register_for_event` (0038) never set `event_registrations.code`, which
-- turns out to be `not null` with a `unique` constraint — every registration
-- attempt failed with a 23502 not-null violation. No app UI reads/displays
-- this column (grepped the whole Dart tree — it's a vestigial internal
-- token), so it just needs a unique value, not a user-legible one.

create or replace function public.register_for_event(_event_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  _event public.events%rowtype;
  _registered_count int;
  _code text;
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

  -- Only needed on first-time insert; the ON CONFLICT UPDATE path below
  -- reuses whatever code the row already has.
  loop
    _code := encode(gen_random_bytes(9), 'hex');
    exit when not exists (select 1 from public.event_registrations where code = _code);
  end loop;

  insert into public.event_registrations (event_id, user_id, status, registered_at, code)
  values (_event_id, auth.uid(), 'registered', now(), _code)
  on conflict (event_id, user_id)
  do update set status = 'registered', registered_at = now();

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.register_for_event(uuid) to authenticated;
