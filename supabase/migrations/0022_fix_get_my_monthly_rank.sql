-- Fix `get_my_monthly_rank`: the `ranked` CTE was scoped to its own `with`
-- statement and referenced again in a second, separate statement where it no
-- longer exists, raising `relation "ranked" does not exist` (42P01) for any
-- account that actually has a monthly rank (my_points > 0). Accounts with no
-- points this month never hit the bug, since the function returns 'unranked'
-- before reaching the broken query — which is why it looked account-specific.
--
-- Fix: recompute the CTE for the second statement instead of reusing it.

create or replace function public.get_my_monthly_rank()
returns jsonb
language plpgsql
stable security definer
set search_path to 'public'
as $function$
declare
  uid uuid := auth.uid();
  my_points bigint;
  my_rank bigint;
  above_pts bigint;
  above_name text;
begin
  if uid is null then return jsonb_build_object('status','unranked'); end if;

  select sum(amount) into my_points
  from public.point_transactions
  where user_id = uid and created_at >= date_trunc('month', now()) and reason <> 'monthly_prize';

  if my_points is null or my_points <= 0 then
    return jsonb_build_object('status','unranked');
  end if;

  with monthly_points as (
    select pt.user_id, sum(pt.amount) as points
    from public.point_transactions pt
    where pt.created_at >= date_trunc('month', now()) and pt.reason <> 'monthly_prize'
    group by pt.user_id
  ), ranked as (
    select user_id, points, rank() over (order by points desc) as rnk
    from monthly_points
  )
  select rnk into my_rank from ranked where user_id = uid;

  with monthly_points as (
    select pt.user_id, sum(pt.amount) as points
    from public.point_transactions pt
    where pt.created_at >= date_trunc('month', now()) and pt.reason <> 'monthly_prize'
    group by pt.user_id
  ), ranked as (
    select user_id, points, rank() over (order by points desc) as rnk
    from monthly_points
  )
  select r.points, p.full_name into above_pts, above_name
  from ranked r join public.profiles p on p.id = r.user_id
  where r.rnk = my_rank - 1
  order by p.full_name asc nulls last
  limit 1;

  return jsonb_build_object(
    'status', 'ok',
    'rank', my_rank,
    'points', my_points,
    'above_name', above_name,
    'gap', case when above_pts is not null then above_pts - my_points else null end
  );
end $function$;
