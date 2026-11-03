-- Make the daily meeting limits roll over at campus midnight, not UTC.
--
-- Every limit check used `current_date` / `::date`, which resolves in the
-- database's timezone (UTC). For an Israeli campus that means the daily
-- counter rolls over at 02:00-03:00 local, so a meeting at 00:30 on Tuesday
-- counted against Monday — students hit "5 partners today" against the wrong
-- day, and the once-per-day pair rule had the same skew.
--
-- Introduces `campus_date()` and routes every meeting-limit date comparison
-- through it, so all paths agree on when a day starts.
--
-- Note: wrapping a column in campus_date() means an index on that column
-- can't be used for these comparisons. The row counts here are small
-- (meetings per pair per day), so this is not worth an expression index yet.

-- ------------------------------------------------------------ campus_date
-- STABLE, not IMMUTABLE: the result depends on the timezone database, and
-- with no argument it depends on now().
create or replace function public.campus_date(_ts timestamptz default now())
returns date
language sql
stable
set search_path to 'public'
as $$
  select (_ts at time zone 'Asia/Jerusalem')::date;
$$;

grant execute on function public.campus_date(timestamptz) to authenticated;

-- --------------------------------------------------- 0059 helpers, retimed
create or replace function public.has_accepted_meeting_with(
  _a uuid,
  _b uuid,
  _day date,
  _exclude_proposal uuid default null
)
returns boolean
language sql
security definer
set search_path to 'public'
as $$
  select exists (
    select 1
    from public.meeting_proposals p
    where p.status = 'accepted'
      and public.campus_date(p.scheduled_at) = _day
      and (_exclude_proposal is null or p.id <> _exclude_proposal)
      and _a in (select m from public.chat_member_ids(p.chat_id) m)
      and _b in (select m from public.chat_member_ids(p.chat_id) m)
  );
$$;

create or replace function public.accepted_meeting_partners_on(
  _user uuid,
  _day date,
  _exclude_proposal uuid default null
)
returns integer
language sql
security definer
set search_path to 'public'
as $$
  select count(distinct other.m)::int
  from public.meeting_proposals p
  cross join lateral (
    select m from public.chat_member_ids(p.chat_id) m where m <> _user
  ) other
  where p.status = 'accepted'
    and public.campus_date(p.scheduled_at) = _day
    and (_exclude_proposal is null or p.id <> _exclude_proposal)
    and _user in (select m from public.chat_member_ids(p.chat_id) m);
$$;

-- ------------------------------------- propose / respond: campus-local day
-- Identical to 0059 except the scheduled date is resolved in campus time.
create or replace function public.propose_meeting(
  _chat_id      uuid,
  _scheduled_at timestamptz,
  _location     text,
  _notes        text,
  _ends_at      timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _chat chats%rowtype;
  _proposal_id uuid;
  _ends_at_resolved timestamptz := coalesce(_ends_at, _scheduled_at + interval '1 hour');
  _me uuid := auth.uid();
  _other uuid;
  _day date := public.campus_date(_scheduled_at);
begin
  select * into _chat from chats where id = _chat_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;
  if _chat.user_a <> _me and _chat.user_b <> _me then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if _ends_at_resolved <= _scheduled_at then
    return jsonb_build_object('status', 'invalid_window');
  end if;

  _other := case when _chat.user_a = _me then _chat.user_b else _chat.user_a end;

  if public.has_accepted_meeting_with(_me, _other, _day) then
    return jsonb_build_object('status', 'daily_pair_limit');
  end if;
  if public.accepted_meeting_partners_on(_me, _day) >= 5 then
    return jsonb_build_object('status', 'daily_partner_limit', 'who', 'self');
  end if;
  if public.accepted_meeting_partners_on(_other, _day) >= 5 then
    return jsonb_build_object('status', 'daily_partner_limit', 'who', 'other');
  end if;

  insert into meeting_proposals (chat_id, proposed_by, scheduled_at, ends_at, location, notes)
  values (_chat_id, _me, _scheduled_at, _ends_at_resolved, _location, _notes)
  returning id into _proposal_id;

  insert into chat_messages (chat_id, sender_id, body, message_type, metadata)
  values (_chat_id, _me, 'Meeting proposal', 'meeting_proposal', jsonb_build_object('proposal_id', _proposal_id));

  return jsonb_build_object('status', 'ok', 'id', _proposal_id);
end;
$$;

create or replace function public.respond_to_meeting_proposal(
  _proposal_id uuid,
  _accept      boolean
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _proposal meeting_proposals%rowtype;
  _chat chats%rowtype;
  _me uuid := auth.uid();
  _other uuid;
  _day date;
begin
  select * into _proposal from meeting_proposals where id = _proposal_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  select * into _chat from chats where id = _proposal.chat_id;
  if _chat.user_a <> _me and _chat.user_b <> _me then
    return jsonb_build_object('status', 'forbidden');
  end if;
  if _proposal.proposed_by = _me then
    return jsonb_build_object('status', 'forbidden');
  end if;
  if _proposal.status <> 'pending' then
    return jsonb_build_object('status', 'already_responded');
  end if;

  if _accept then
    _other := _proposal.proposed_by;
    _day := public.campus_date(_proposal.scheduled_at);

    if public.has_accepted_meeting_with(_me, _other, _day, _proposal_id) then
      return jsonb_build_object('status', 'daily_pair_limit');
    end if;
    if public.accepted_meeting_partners_on(_me, _day, _proposal_id) >= 5 then
      return jsonb_build_object('status', 'daily_partner_limit', 'who', 'self');
    end if;
    if public.accepted_meeting_partners_on(_other, _day, _proposal_id) >= 5 then
      return jsonb_build_object('status', 'daily_partner_limit', 'who', 'other');
    end if;
  end if;

  update meeting_proposals set status = case when _accept then 'accepted' else 'declined' end
  where id = _proposal_id;

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.propose_meeting(uuid, timestamptz, text, text, timestamptz) to authenticated;
grant execute on function public.respond_to_meeting_proposal(uuid, boolean) to authenticated;

-- ------------------------------------------- scan_meeting_qr, campus-local
-- Body preserved from 0052; only the three day comparisons change, from
-- `completed_at::date = now()::date` (UTC) to campus_date() on both sides.
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
      where public.campus_date(mc.completed_at) = public.campus_date()
        and ((ck.scanner_id = v_me and ck.scanned_id = v_owner)
          or (ck.scanner_id = v_owner and ck.scanned_id = v_me))
    ) into v_today_pair;

    if not v_today_pair then
      select count(distinct case when ck.scanner_id = v_me then ck.scanned_id else ck.scanner_id end)
        into v_me_partners_today
      from public.meeting_checkins ck
      join public.meeting_completions mc on mc.proposal_id = ck.proposal_id
      where public.campus_date(mc.completed_at) = public.campus_date()
        and (ck.scanner_id = v_me or ck.scanned_id = v_me);

      select count(distinct case when ck.scanner_id = v_owner then ck.scanned_id else ck.scanner_id end)
        into v_owner_partners_today
      from public.meeting_checkins ck
      join public.meeting_completions mc on mc.proposal_id = ck.proposal_id
      where public.campus_date(mc.completed_at) = public.campus_date()
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

-- -------------------------------------- award_meeting_points, campus-local
-- The group-meeting points path. Body preserved from the deployed function;
-- only its three day comparisons change from UTC `::date = current_date` to
-- campus_date() on both sides, matching scan_meeting_qr.
create or replace function public.award_meeting_points(
  _user_a uuid,
  _user_b uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _ua uuid := least(_user_a, _user_b);
  _ub uuid := greatest(_user_a, _user_b);
  _prev_count int;
  _prev_last timestamptz;
  _new_count int;
  _points int;
  _reason text;
  _a_partners_today int;
  _b_partners_today int;
  _first_meeting boolean;
begin
  select meeting_count, last_meeting_at into _prev_count, _prev_last
  from meeting_pair_history where user_a = _ua and user_b = _ub for update;

  _first_meeting := _prev_count is null;

  if _prev_last is not null
     and public.campus_date(_prev_last) = public.campus_date() then
    return jsonb_build_object('points', 0, 'capped', true, 'first_meeting', _first_meeting);
  end if;

  select count(distinct case when user_a = _user_a then user_b else user_a end) into _a_partners_today
  from meeting_pair_history
  where (user_a = _user_a or user_b = _user_a)
    and public.campus_date(last_meeting_at) = public.campus_date();

  select count(distinct case when user_a = _user_b then user_b else user_a end) into _b_partners_today
  from meeting_pair_history
  where (user_a = _user_b or user_b = _user_b)
    and public.campus_date(last_meeting_at) = public.campus_date();

  if _a_partners_today >= 5 or _b_partners_today >= 5 then
    return jsonb_build_object('points', 0, 'capped', true, 'first_meeting', _first_meeting);
  end if;

  _new_count := coalesce(_prev_count, 0) + 1;
  _points := case when _new_count = 1 then 25 when _new_count = 2 then 20 else 10 end;
  _reason := case when _new_count = 1 then 'meeting_first' when _new_count = 2 then 'meeting_second' else 'meeting_repeat' end;

  insert into meeting_pair_history (user_a, user_b, meeting_count, last_meeting_at)
  values (_ua, _ub, _new_count, now())
  on conflict (user_a, user_b) do update set meeting_count = excluded.meeting_count, last_meeting_at = excluded.last_meeting_at;

  return jsonb_build_object('points', _points, 'capped', false, 'first_meeting', _first_meeting, 'reason', _reason);
end;
$$;
