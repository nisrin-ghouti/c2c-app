-- Survey management was accidentally scoped to the super admin only (the
-- admin panel screen has now been un-gated too) — every other admin-facing
-- module (events, benefits, option lists) allows any user with the 'admin'
-- role, so surveys should match that instead of requiring is_super_admin.

create or replace function public.admin_list_surveys()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not exists (select 1 from public.user_roles where user_id = auth.uid() and role = 'admin') then
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
  if not exists (select 1 from public.user_roles where user_id = auth.uid() and role = 'admin') then
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
  if not exists (select 1 from public.user_roles where user_id = auth.uid() and role = 'admin') then
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

create or replace function public.admin_set_survey_published(_id uuid, _published boolean)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not exists (select 1 from public.user_roles where user_id = auth.uid() and role = 'admin') then
    return jsonb_build_object('status', 'forbidden');
  end if;

  update public.surveys set is_published = _published, updated_at = now() where id = _id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  return jsonb_build_object('status', 'ok');
end;
$$;

create or replace function public.admin_delete_survey(_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not exists (select 1 from public.user_roles where user_id = auth.uid() and role = 'admin') then
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
