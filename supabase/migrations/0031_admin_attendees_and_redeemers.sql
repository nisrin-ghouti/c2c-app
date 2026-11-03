-- Surfaces exactly who attended an event and who redeemed a benefit,
-- including gender (for the male/female breakdown the admin panel now
-- shows), so an admin doesn't have to infer this from aggregate counts.

-- 1. Add gender to the existing event-registrants RPC (additive — same
--    signature, same guard, just one more field in the returned rows).
create or replace function public.admin_list_event_registrants(_event_id uuid, _session_id uuid default null::uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _row public.events%rowtype;
  _can_manage boolean;
begin
  select * into _row from public.events where id = _event_id;
  if not found then
    return '[]'::jsonb;
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
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'user_id', p.id,
        'full_name', p.full_name,
        'email', p.email,
        'gender', p.gender,
        'registered_at', r.registered_at,
        'attended_at', a.scanned_at
      ) order by r.registered_at)
      from public.event_registrations r
      join public.profiles p on p.id = r.user_id
      left join public.event_attendance a
        on a.event_id = r.event_id
        and a.user_id = r.user_id
        and coalesce(a.session_id, '00000000-0000-0000-0000-000000000000'::uuid) = coalesce(_session_id, '00000000-0000-0000-0000-000000000000'::uuid)
      where r.event_id = _event_id
        and r.session_id is null
        and r.status = 'registered'
    ),
    '[]'::jsonb
  );
end;
$$;

-- 2. Who actually redeemed a benefit (digital_cards.redeemed_at is not
--    null — set only once the business partner confirms via QR scan, not
--    at the moment a student merely claims/spends points on it).
create or replace function public.admin_list_benefit_redeemers(_benefit_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.is_admin() then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'user_id', p.id,
        'full_name', p.full_name,
        'email', p.email,
        'gender', p.gender,
        'points_spent', c.points_spent,
        'redeemed_at', c.redeemed_at
      ) order by c.redeemed_at desc)
      from public.digital_cards c
      join public.profiles p on p.id = c.user_id
      where c.benefit_id = _benefit_id
        and c.redeemed_at is not null
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.admin_list_benefit_redeemers(uuid) to authenticated;
