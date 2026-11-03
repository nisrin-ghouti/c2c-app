-- Two spec-mandated limits that were missing server-side:
--
-- 1. `scan_meeting_qr` (direct 1-on-1 meeting scan path) never enforced the
--    "5 distinct partners per day" cap — only the group-meeting fallback
--    path (`award_meeting_points`) had it. Ported the same rule in here,
--    using this function's own meeting_completions/meeting_checkins model
--    (award_meeting_points uses a separate meeting_pair_history table, but
--    the two point-awarding paths have always used different underlying
--    tables — not reconciling that here, just matching its cap behavior:
--    if either participant already has 5 distinct partners today, this
--    meeting awards 0 points to both, same as award_meeting_points does).
--
-- 2. `create_group_meeting` never validated _max_participants server-side
--    (only the client's Slider constrained it to 3-10) — a direct RPC call
--    could create a group meeting with any size.

create or replace function public.scan_meeting_qr(_raw text)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_token     text := replace(coalesce(_raw, ''), 'c2c:meeting:', '');
  v_owner     uuid;
  v_proposal  uuid;
  v_expires   timestamptz;
  v_me        uuid := auth.uid();
  v_reverse   boolean;
  v_points    int := 0;
  v_prior     int;
  v_reason    text;
  v_today_pair boolean;
  v_me_partners_today int;
  v_owner_partners_today int;
begin
  if not public.is_student_eligible(v_me) then
    return jsonb_build_object('status', 'not_a_student');
  end if;

  select user_id, proposal_id, expires_at
    into v_owner, v_proposal, v_expires
  from public.meeting_scan_tokens
  where token = v_token;

  if v_owner is null then
    return jsonb_build_object('status', 'invalid');
  end if;
  if v_owner = v_me then
    return jsonb_build_object('status', 'own_code');
  end if;
  if now() > v_expires then
    return jsonb_build_object('status', 'expired', 'other_user_id', v_owner);
  end if;

  insert into public.meeting_checkins (proposal_id, scanner_id, scanned_id)
  values (v_proposal, v_me, v_owner)
  on conflict (proposal_id, scanner_id) do nothing;

  select exists (
    select 1 from public.meeting_checkins
    where proposal_id = v_proposal and scanner_id = v_owner and scanned_id = v_me
  ) into v_reverse;

  if v_reverse and not exists (
    select 1 from public.meeting_completions where proposal_id = v_proposal
  ) then
    select exists (
      select 1
      from public.meeting_completions mc
      join public.meeting_checkins ck on ck.proposal_id = mc.proposal_id
      where mc.completed_at::date = now()::date
        and ((ck.scanner_id = v_me and ck.scanned_id = v_owner)
          or (ck.scanner_id = v_owner and ck.scanned_id = v_me))
    ) into v_today_pair;

    if not v_today_pair then
      select count(distinct case when ck.scanner_id = v_me then ck.scanned_id else ck.scanner_id end)
        into v_me_partners_today
      from public.meeting_checkins ck
      join public.meeting_completions mc on mc.proposal_id = ck.proposal_id
      where mc.completed_at::date = now()::date
        and (ck.scanner_id = v_me or ck.scanned_id = v_me);

      select count(distinct case when ck.scanner_id = v_owner then ck.scanned_id else ck.scanner_id end)
        into v_owner_partners_today
      from public.meeting_checkins ck
      join public.meeting_completions mc on mc.proposal_id = ck.proposal_id
      where mc.completed_at::date = now()::date
        and (ck.scanner_id = v_owner or ck.scanned_id = v_owner);

      if coalesce(v_me_partners_today, 0) < 5 and coalesce(v_owner_partners_today, 0) < 5 then
        select count(*) into v_prior
        from public.meeting_completions mc
        join public.meeting_checkins ck on ck.proposal_id = mc.proposal_id
        where (ck.scanner_id = v_me and ck.scanned_id = v_owner);

        if v_prior = 0 then
          v_points := 25; v_reason := 'meeting_first';
        elsif v_prior = 1 then
          v_points := 20; v_reason := 'meeting_second';
        else
          v_points := 10; v_reason := 'meeting_repeat';
        end if;

        insert into public.point_transactions (user_id, amount, reason, metadata)
        select uid, v_points, v_reason,
               jsonb_build_object('proposal_id', v_proposal, 'other_user_id',
                 case when uid = v_me then v_owner else v_me end)
        from (values (v_me), (v_owner)) as t(uid)
        where public.is_student_eligible(uid);
      end if;
    end if;

    insert into public.meeting_completions (proposal_id, points_each)
    values (v_proposal, v_points)
    on conflict (proposal_id) do nothing;
  end if;

  return jsonb_build_object(
    'status', 'ok',
    'other_user_id', v_owner,
    'i_scanned_them', true,
    'they_scanned_me', v_reverse,
    'completed', v_reverse,
    'points', v_points
  );
end;
$function$;

create or replace function public.create_group_meeting(
  _title text,
  _description text,
  _scheduled_at timestamptz,
  _location text,
  _max_participants int default 10
)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if _max_participants is null or _max_participants not between 3 and 10 then
    return jsonb_build_object('status', 'invalid_size');
  end if;

  insert into group_meetings (organizer_id, title, description, scheduled_at, location, max_participants)
  values (auth.uid(), _title, _description, _scheduled_at, _location, _max_participants);
  return jsonb_build_object('status', 'ok');
end;
$function$;
