-- Cross-event/cross-benefit analytics for the admin dashboard's Analytics
-- module — everything the mobile app's per-event `get_event_stats` doesn't
-- cover: participation totals, which events draw the most registrations,
-- registration trend over time, and benefit redemption (cards issued vs.
-- actually used). All admin-only, same guard pattern as `is_admin()`
-- already uses elsewhere; a non-admin caller gets an empty result rather
-- than an error, matching `admin_list_pending_events`'s convention.

-- 1. Overall event participation summary ------------------------------------
create or replace function public.admin_event_participation_summary()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.is_admin() then
    return jsonb_build_object();
  end if;

  return jsonb_build_object(
    'total_events', (select count(*) from public.events),
    'total_unique_participants', (select count(distinct user_id) from public.event_registrations),
    'total_registrations', (select count(*) from public.event_registrations),
    'total_attendance', (select count(*) from public.event_registrations where attended_at is not null)
  );
end;
$$;

grant execute on function public.admin_event_participation_summary() to authenticated;

-- 2. Top events by registration count ----------------------------------------
create or replace function public.admin_top_events_by_registrations(_limit int default 10)
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
      select jsonb_agg(row_to_json(t))
      from (
        select
          e.id as event_id,
          e.title,
          e.starts_at,
          count(r.id) as registrations,
          count(r.attended_at) as attendance
        from public.events e
        left join public.event_registrations r on r.event_id = e.id
        group by e.id, e.title, e.starts_at
        order by registrations desc, e.starts_at desc
        limit _limit
      ) t
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.admin_top_events_by_registrations(int) to authenticated;

-- 3. Daily registration counts, trailing N days ------------------------------
create or replace function public.admin_registrations_over_time(_days int default 30)
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
      select jsonb_agg(row_to_json(t) order by t.day)
      from (
        select date_trunc('day', r.registered_at)::date as day, count(*) as registrations
        from public.event_registrations r
        where r.registered_at >= (current_date - _days)
        group by 1
      ) t
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.admin_registrations_over_time(int) to authenticated;

-- 4. Benefit redemption summary (cards issued vs. actually used) ------------
create or replace function public.admin_benefit_redemption_summary()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.is_admin() then
    return jsonb_build_object();
  end if;

  return jsonb_build_object(
    'total_issued', (select count(*) from public.digital_cards),
    'total_redeemed', (select count(*) from public.digital_cards where status = 'redeemed'),
    'total_unredeemed', (select count(*) from public.digital_cards where status <> 'redeemed'),
    'total_points_spent', (select coalesce(sum(points_spent), 0) from public.digital_cards)
  );
end;
$$;

grant execute on function public.admin_benefit_redemption_summary() to authenticated;

-- 5. Per-benefit issued/redeemed breakdown -----------------------------------
create or replace function public.admin_benefit_redemptions_by_benefit()
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
      select jsonb_agg(row_to_json(t) order by t.issued desc)
      from (
        select
          b.id as benefit_id,
          b.title,
          b.partner_business_name,
          count(c.id) as issued,
          count(c.id) filter (where c.status = 'redeemed') as redeemed
        from public.benefits b
        left join public.digital_cards c on c.benefit_id = b.id
        group by b.id, b.title, b.partner_business_name
      ) t
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.admin_benefit_redemptions_by_benefit() to authenticated;

-- 6. Daily redemption counts, trailing N days --------------------------------
create or replace function public.admin_redemptions_over_time(_days int default 30)
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
      select jsonb_agg(row_to_json(t) order by t.day)
      from (
        select date_trunc('day', c.redeemed_at)::date as day, count(*) as redemptions
        from public.digital_cards c
        where c.status = 'redeemed' and c.redeemed_at >= (current_date - _days)
        group by 1
      ) t
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.admin_redemptions_over_time(int) to authenticated;
