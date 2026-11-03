-- Surveys — students complete admin-authored surveys (single/multi choice,
-- rating, free text questions) and earn a fixed point reward once, per
-- survey. Creation/management is super-admin only; visibility can be
-- targeted to specific faculties (same shape as `event_visibility_targets`
-- — no target rows means visible to everyone). State (incoming/pending/
-- completed) is computed from `opens_at`/`closes_at` + whether the caller
-- already has a `survey_responses` row, not stored.

-- 1. Tables --------------------------------------------------------------

create table public.surveys (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  points integer not null default 0,
  opens_at timestamptz not null default now(),
  closes_at timestamptz,
  is_published boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.survey_questions (
  id uuid primary key default gen_random_uuid(),
  survey_id uuid not null references public.surveys(id) on delete cascade,
  question_type text not null check (question_type in ('single_choice', 'multi_choice', 'rating', 'text')),
  prompt text not null,
  sort_order integer not null default 0,
  rating_max integer
);

create table public.survey_question_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.survey_questions(id) on delete cascade,
  label text not null,
  sort_order integer not null default 0
);

create table public.survey_targets (
  survey_id uuid not null references public.surveys(id) on delete cascade,
  target_type text not null default 'faculty',
  target_value text not null,
  primary key (survey_id, target_type, target_value)
);

create table public.survey_responses (
  id uuid primary key default gen_random_uuid(),
  survey_id uuid not null references public.surveys(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  submitted_at timestamptz not null default now(),
  points_awarded integer not null default 0,
  unique (survey_id, user_id)
);

create table public.survey_answers (
  id uuid primary key default gen_random_uuid(),
  response_id uuid not null references public.survey_responses(id) on delete cascade,
  question_id uuid not null references public.survey_questions(id),
  answer jsonb not null
);

alter table public.surveys enable row level security;
alter table public.survey_questions enable row level security;
alter table public.survey_question_options enable row level security;
alter table public.survey_targets enable row level security;
alter table public.survey_responses enable row level security;
alter table public.survey_answers enable row level security;

-- All access to these tables goes through the SECURITY DEFINER RPCs below
-- (same approach as `events`/`benefits` admin paths) — no direct-select
-- policies needed since PostgREST table access isn't used for surveys.

-- 2. Shared helper --------------------------------------------------------

create or replace function public._is_super_admin()
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select coalesce((select is_super_admin from public.profiles where id = auth.uid()), false);
$$;

-- 3. Admin management RPCs -------------------------------------------------

create or replace function public.admin_list_surveys()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public._is_super_admin() then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(row_to_json(t) order by t.created_at desc)
      from (
        select
          s.id, s.title, s.description, s.points, s.opens_at, s.closes_at,
          s.is_published, s.created_at,
          (select count(*) from public.survey_responses r where r.survey_id = s.id) as response_count
        from public.surveys s
      ) t
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.admin_list_surveys() to authenticated;

create or replace function public.admin_create_survey(_survey jsonb, _questions jsonb, _targets jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _id uuid;
  _q jsonb;
  _opt jsonb;
  _question_id uuid;
  _i int;
begin
  if not public._is_super_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  insert into public.surveys (title, description, points, opens_at, closes_at, is_published, created_by)
  values (
    _survey->>'title',
    _survey->>'description',
    coalesce((_survey->>'points')::int, 0),
    coalesce((_survey->>'opens_at')::timestamptz, now()),
    nullif(_survey->>'closes_at', '')::timestamptz,
    coalesce((_survey->>'is_published')::boolean, false),
    auth.uid()
  )
  returning id into _id;

  _i := 0;
  for _q in select * from jsonb_array_elements(coalesce(_questions, '[]'::jsonb))
  loop
    insert into public.survey_questions (survey_id, question_type, prompt, sort_order, rating_max)
    values (
      _id,
      _q->>'question_type',
      _q->>'prompt',
      _i,
      nullif(_q->>'rating_max', '')::int
    )
    returning id into _question_id;

    for _opt in select * from jsonb_array_elements(coalesce(_q->'options', '[]'::jsonb))
    loop
      insert into public.survey_question_options (question_id, label, sort_order)
      values (_question_id, _opt->>'label', coalesce((_opt->>'sort_order')::int, 0));
    end loop;

    _i := _i + 1;
  end loop;

  insert into public.survey_targets (survey_id, target_type, target_value)
  select _id, coalesce(t->>'target_type', 'faculty'), t->>'target_value'
  from jsonb_array_elements(coalesce(_targets, '[]'::jsonb)) t;

  return jsonb_build_object('status', 'ok', 'id', _id);
end;
$$;

grant execute on function public.admin_create_survey(jsonb, jsonb, jsonb) to authenticated;

create or replace function public.admin_update_survey(_id uuid, _survey jsonb, _questions jsonb, _targets jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _q jsonb;
  _opt jsonb;
  _question_id uuid;
  _i int;
begin
  if not public._is_super_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if not exists (select 1 from public.surveys where id = _id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  update public.surveys set
    title = _survey->>'title',
    description = _survey->>'description',
    points = coalesce((_survey->>'points')::int, 0),
    opens_at = coalesce((_survey->>'opens_at')::timestamptz, now()),
    closes_at = nullif(_survey->>'closes_at', '')::timestamptz,
    is_published = coalesce((_survey->>'is_published')::boolean, false),
    updated_at = now()
  where id = _id;

  delete from public.survey_questions where survey_id = _id;
  delete from public.survey_targets where survey_id = _id;

  _i := 0;
  for _q in select * from jsonb_array_elements(coalesce(_questions, '[]'::jsonb))
  loop
    insert into public.survey_questions (survey_id, question_type, prompt, sort_order, rating_max)
    values (
      _id,
      _q->>'question_type',
      _q->>'prompt',
      _i,
      nullif(_q->>'rating_max', '')::int
    )
    returning id into _question_id;

    for _opt in select * from jsonb_array_elements(coalesce(_q->'options', '[]'::jsonb))
    loop
      insert into public.survey_question_options (question_id, label, sort_order)
      values (_question_id, _opt->>'label', coalesce((_opt->>'sort_order')::int, 0));
    end loop;

    _i := _i + 1;
  end loop;

  insert into public.survey_targets (survey_id, target_type, target_value)
  select _id, coalesce(t->>'target_type', 'faculty'), t->>'target_value'
  from jsonb_array_elements(coalesce(_targets, '[]'::jsonb)) t;

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.admin_update_survey(uuid, jsonb, jsonb, jsonb) to authenticated;

create or replace function public.admin_set_survey_published(_id uuid, _published boolean)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public._is_super_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  update public.surveys set is_published = _published, updated_at = now() where id = _id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.admin_set_survey_published(uuid, boolean) to authenticated;

create or replace function public.admin_delete_survey(_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public._is_super_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if exists (select 1 from public.survey_responses where survey_id = _id) then
    return jsonb_build_object('status', 'has_responses');
  end if;

  delete from public.surveys where id = _id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.admin_delete_survey(uuid) to authenticated;

-- 4. Student-facing RPCs ----------------------------------------------------

create or replace function public.list_available_surveys()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  return coalesce(
    (
      select jsonb_agg(row_to_json(t) order by t.opens_at)
      from (
        select
          s.id, s.title, s.description, s.points, s.opens_at, s.closes_at,
          case
            when r.id is not null then 'completed'
            when s.opens_at > now() then 'incoming'
            else 'pending'
          end as state
        from public.surveys s
        left join public.survey_responses r on r.survey_id = s.id and r.user_id = auth.uid()
        where s.is_published
          and (s.closes_at is null or s.closes_at > now() or r.id is not null)
          and (
            not exists (select 1 from public.survey_targets t where t.survey_id = s.id)
            or exists (
              select 1 from public.survey_targets t
              join public.profiles p on p.id = auth.uid()
              where t.survey_id = s.id
                and t.target_type = 'faculty'
                and t.target_value = any(coalesce(p.faculties, array[]::text[]))
            )
          )
      ) t
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.list_available_surveys() to authenticated;

create or replace function public.get_survey_detail(_survey_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _survey record;
  _visible boolean;
begin
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

  if exists (select 1 from public.survey_responses where survey_id = _survey_id and user_id = auth.uid()) then
    return jsonb_build_object('status', 'already_answered');
  end if;

  if _survey.opens_at > now() then
    return jsonb_build_object('status', 'not_yet_open');
  end if;

  if _survey.closes_at is not null and _survey.closes_at <= now() then
    return jsonb_build_object('status', 'closed');
  end if;

  return jsonb_build_object(
    'status', 'ok',
    'survey', jsonb_build_object(
      'id', _survey.id, 'title', _survey.title, 'description', _survey.description,
      'points', _survey.points
    ),
    'questions', coalesce(
      (
        select jsonb_agg(row_to_json(q) order by q.sort_order)
        from (
          select
            sq.id, sq.question_type, sq.prompt, sq.sort_order, sq.rating_max,
            coalesce(
              (
                select jsonb_agg(jsonb_build_object('id', o.id, 'label', o.label) order by o.sort_order)
                from public.survey_question_options o
                where o.question_id = sq.id
              ),
              '[]'::jsonb
            ) as options
          from public.survey_questions sq
          where sq.survey_id = _survey_id
        ) q
      ),
      '[]'::jsonb
    )
  );
end;
$$;

grant execute on function public.get_survey_detail(uuid) to authenticated;

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

grant execute on function public.submit_survey_response(uuid, jsonb) to authenticated;
