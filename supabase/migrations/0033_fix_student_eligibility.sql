-- CORRECTS 0032: self-registered students never get an explicit 'student'
-- row in user_roles (only admin-created accounts do) — confirmed live:
-- 12 of 17 real accounts have zero user_roles rows at all. 0032's guards
-- (`has_role(uid, 'student')`) would therefore reject scan/redeem/survey
-- attempts from ordinary real students, not just Admin/Host-only accounts.
--
-- Correct rule: "eligible as a student" means the account has no elevated
-- role at all (the historical implicit default — a plain signup with zero
-- role rows), OR it explicitly holds the 'student' role even alongside
-- admin/host. Only an account with admin and/or host but *no* explicit
-- student grant is excluded — exactly "Admin/Host-only", per spec.
create or replace function public.is_student_eligible(_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    not exists (
      select 1 from public.user_roles
      where user_id = _user_id and role in ('admin'::app_role, 'host'::app_role)
    )
    or exists (
      select 1 from public.user_roles
      where user_id = _user_id and role = 'student'::app_role
    );
$$;

grant execute on function public.is_student_eligible(uuid) to authenticated;

create or replace function public.list_match_candidates()
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select coalesce(jsonb_agg(row_to_json(c) order by c.created_at desc), '[]'::jsonb)
  from (
    select
      p.id, p.full_name, p.faculty, p.field_of_study, p.faculties, p.fields_of_study,
      p.degree, p.year, p.bio, p.avatar_hue, p.avatar_url, p.hobbies, p.interests,
      p.languages, p.created_at
    from public.profiles p
    where p.id <> auth.uid()
      and p.deleted_at is null
      and public.is_student_eligible(p.id)
    order by p.created_at desc
    limit 200
  ) c;
$$;

create or replace function public.scan_event_attendance(_token uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _token_row public.event_qr_tokens%rowtype;
  _event public.events%rowtype;
  _already record;
  _registered record;
begin
  if not public.is_student_eligible(auth.uid()) then
    return jsonb_build_object('status', 'not_a_student');
  end if;

  select * into _token_row from public.event_qr_tokens where token = _token
    order by issued_at desc limit 1;
  if not found then
    return jsonb_build_object('status', 'invalid');
  end if;

  select * into _event from public.events where id = _token_row.event_id;
  if not found then
    return jsonb_build_object('status', 'invalid');
  end if;

  if not _event.qr_enabled then
    return jsonb_build_object('status', 'scanning_closed');
  end if;

  if now() > _token_row.expires_at then
    return jsonb_build_object('status', 'expired');
  end if;

  select * into _already from public.event_attendance
    where event_id = _token_row.event_id
      and coalesce(session_id, '00000000-0000-0000-0000-000000000000'::uuid)
        = coalesce(_token_row.session_id, '00000000-0000-0000-0000-000000000000'::uuid)
      and user_id = auth.uid();
  if found then
    return jsonb_build_object('status', 'already_scanned');
  end if;

  select * into _registered from public.event_registrations
    where event_id = _token_row.event_id
      and coalesce(session_id, '00000000-0000-0000-0000-000000000000'::uuid)
        = coalesce(_token_row.session_id, '00000000-0000-0000-0000-000000000000'::uuid)
      and user_id = auth.uid()
      and status = 'registered';
  if not found then
    return jsonb_build_object('status', 'not_registered');
  end if;

  insert into public.event_attendance (event_id, session_id, user_id, points_awarded)
  values (_token_row.event_id, _token_row.session_id, auth.uid(), _event.points);

  insert into public.point_transactions (user_id, amount, reason, metadata)
  values (auth.uid(), _event.points, 'event_attendance', jsonb_build_object('event_id', _event.id, 'event_title', _event.title));

  return jsonb_build_object('status', 'ok', 'points', _event.points, 'event_title', _event.title);
end;
$$;

create or replace function public.confirm_attendance_by_student_id(_event_id uuid, _student_id text, _session_id uuid default null::uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id  uuid;
  v_event    public.events%rowtype;
  v_points   int;
  v_title    text;
begin
  select * into v_event from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'invalid', 'points', 0);
  end if;
  v_title := v_event.title;

  if not public.is_admin() and v_event.created_by <> auth.uid() then
    return jsonb_build_object('status', 'invalid', 'points', 0, 'event_title', v_title);
  end if;

  select id into v_user_id
  from public.profiles
  where student_id = regexp_replace(coalesce(_student_id, ''), '\s', '', 'g');

  if v_user_id is null then
    return jsonb_build_object('status', 'invalid', 'points', 0, 'event_title', v_title);
  end if;

  if not public.is_student_eligible(v_user_id) then
    return jsonb_build_object('status', 'not_a_student', 'points', 0, 'event_title', v_title);
  end if;

  if not exists (
    select 1 from public.event_registrations
    where event_id = _event_id and user_id = v_user_id
  ) then
    return jsonb_build_object('status', 'not_registered', 'points', 0, 'event_title', v_title);
  end if;

  if exists (
    select 1 from public.event_attendance
    where event_id = _event_id
      and user_id  = v_user_id
      and (_session_id is null or session_id = _session_id)
  ) then
    return jsonb_build_object('status', 'already_scanned', 'points', 0, 'event_title', v_title);
  end if;

  v_points := coalesce(v_event.points, 0);

  insert into public.event_attendance (event_id, user_id, session_id)
  values (_event_id, v_user_id, _session_id);

  if v_points > 0 then
    insert into public.point_transactions (user_id, amount, reason, metadata)
    values (
      v_user_id,
      v_points,
      'event_attendance',
      jsonb_build_object(
        'event_id',     _event_id,
        'session_id',   _session_id,
        'event_title',  v_title,
        'confirmed_by', auth.uid(),
        'method',       'student_id'
      )
    );
  end if;

  return jsonb_build_object('status', 'ok', 'points', v_points, 'event_title', v_title);
end;
$$;

create or replace function public.scan_meeting_qr(_raw text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
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
$$;

create or replace function public.finish_group_meeting(_group_meeting_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_gm group_meetings%rowtype;
  v_scan_count int;
  v_scanner_id uuid;
  v_award jsonb;
  v_points int;
  v_organizer_points int := 0;
  v_paid_scanners int := 0;
  v_organizer_today_count int;
  v_scanner_today_count int;
begin
  select * into v_gm from group_meetings where id = _group_meeting_id for update;

  if not found or v_gm.organizer_id <> auth.uid() then
    return jsonb_build_object('status', 'forbidden');
  end if;
  if v_gm.finished_at is not null then
    return jsonb_build_object('status', 'already_finished');
  end if;

  update group_meetings set finished_at = now() where id = _group_meeting_id;

  select count(*) into v_scan_count from group_meeting_scans where group_meeting_id = _group_meeting_id;

  if v_scan_count = 0 then
    return jsonb_build_object('status', 'ok', 'outcome', 'no_scans', 'scan_count', 0);
  end if;

  if v_scan_count = 1 then
    select scanner_id into v_scanner_id from group_meeting_scans where group_meeting_id = _group_meeting_id;

    v_award := award_meeting_points(v_gm.organizer_id, v_scanner_id);
    v_points := (v_award->>'points')::int;

    if (v_award->>'capped')::boolean then
      return jsonb_build_object('status', 'ok', 'outcome', 'one_to_one_capped', 'scan_count', 1);
    end if;

    insert into point_transactions (user_id, amount, reason)
    select uid, v_points, v_award->>'reason'
    from (values (v_gm.organizer_id), (v_scanner_id)) as t(uid)
    where public.is_student_eligible(uid);

    return jsonb_build_object('status', 'ok', 'outcome', 'one_to_one', 'points', v_points, 'scan_count', 1);
  end if;

  select count(distinct group_meeting_id) into v_organizer_today_count
  from point_transactions
  where user_id = v_gm.organizer_id and reason = 'group_meeting' and created_at::date = current_date;

  if v_organizer_today_count < 2 and public.is_student_eligible(v_gm.organizer_id) then
    insert into point_transactions (user_id, amount, reason, group_meeting_id)
    values (v_gm.organizer_id, 25, 'group_meeting', _group_meeting_id);
    v_organizer_points := 25;
  end if;

  for v_scanner_id in select scanner_id from group_meeting_scans where group_meeting_id = _group_meeting_id loop
    if not public.is_student_eligible(v_scanner_id) then
      continue;
    end if;

    select count(distinct group_meeting_id) into v_scanner_today_count
    from point_transactions
    where user_id = v_scanner_id and reason = 'group_meeting' and created_at::date = current_date;

    if v_scanner_today_count < 2 then
      insert into point_transactions (user_id, amount, reason, group_meeting_id)
      values (v_scanner_id, 15, 'group_meeting', _group_meeting_id);
      v_paid_scanners := v_paid_scanners + 1;
    end if;
  end loop;

  return jsonb_build_object(
    'status', 'ok', 'outcome', 'group',
    'organizer_points', v_organizer_points, 'paid_scanners', v_paid_scanners, 'scan_count', v_scan_count
  );
end;
$$;

create or replace function public.submit_survey_response(_survey_id uuid, _answers jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _survey record;
  _visible boolean;
  _response_id uuid;
  _a jsonb;
begin
  if not public.is_student_eligible(auth.uid()) then
    return jsonb_build_object('status', 'not_a_student');
  end if;

  select * into _survey from public.surveys where id = _survey_id and is_published;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  select
    not exists (select 1 from public.survey_targets t where t.survey_id = _survey_id)
    or exists (
      select 1 from public.survey_targets t
      join public.profiles p on p.id = auth.uid()
      where t.survey_id = _survey_id
        and t.target_type = 'faculty'
        and t.target_value = any(coalesce(p.faculties, array[]::text[]))
    )
  into _visible;

  if not _visible then
    return jsonb_build_object('status', 'not_found');
  end if;

  if _survey.opens_at > now() then
    return jsonb_build_object('status', 'not_yet_open');
  end if;

  if _survey.closes_at is not null and _survey.closes_at <= now() then
    return jsonb_build_object('status', 'closed');
  end if;

  if exists (select 1 from public.survey_responses where survey_id = _survey_id and user_id = auth.uid()) then
    return jsonb_build_object('status', 'already_answered');
  end if;

  insert into public.survey_responses (survey_id, user_id, points_awarded)
  values (_survey_id, auth.uid(), _survey.points)
  returning id into _response_id;

  for _a in select * from jsonb_array_elements(coalesce(_answers, '[]'::jsonb))
  loop
    insert into public.survey_answers (response_id, question_id, answer)
    values (_response_id, (_a->>'question_id')::uuid, _a->'answer');
  end loop;

  if _survey.points > 0 then
    insert into public.point_transactions (user_id, amount, reason, metadata)
    values (
      auth.uid(),
      _survey.points,
      'survey_completed',
      jsonb_build_object('survey_id', _survey_id, 'survey_title', _survey.title)
    );
  end if;

  return jsonb_build_object('status', 'ok', 'points', _survey.points);
end;
$$;

create or replace function public.redeem_benefit(_benefit_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  _benefit benefits%rowtype;
  _balance int;
  _card_id uuid;
  _qr_token text;
begin
  if not public.is_student_eligible(auth.uid()) then
    return jsonb_build_object('status', 'not_a_student');
  end if;

  select * into _benefit from benefits where id = _benefit_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;
  if not _benefit.active then
    return jsonb_build_object('status', 'inactive');
  end if;

  select coalesce(sum(amount), 0) into _balance from point_transactions where user_id = auth.uid();
  if _balance < _benefit.point_cost then
    return jsonb_build_object('status', 'insufficient_points');
  end if;

  insert into point_transactions (user_id, amount, reason, metadata)
  values (auth.uid(), -_benefit.point_cost, 'benefit_redeem', jsonb_build_object('benefit_id', _benefit_id));

  _qr_token := encode(gen_random_bytes(12), 'hex');

  insert into digital_cards (benefit_id, user_id, qr_token, points_spent)
  values (_benefit_id, auth.uid(), _qr_token, _benefit.point_cost)
  returning id into _card_id;

  return jsonb_build_object(
    'status', 'ok',
    'id', _card_id,
    'benefit_id', _benefit_id,
    'title', _benefit.title,
    'description', _benefit.description,
    'category', _benefit.category,
    'image_url', _benefit.image_url,
    'partner_business_name', _benefit.partner_business_name,
    'qr_token', _qr_token,
    'points_spent', _benefit.point_cost,
    'redeemed_at', null,
    'created_at', now()
  );
end;
$$;
