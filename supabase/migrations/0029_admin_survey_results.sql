-- Per-question aggregated survey results — the actual answers view that
-- was missing: the management table only ever showed a response count,
-- with no way to see what students actually said. Choice/rating questions
-- get vote counts (for bar-chart display); free text gets the raw list
-- (nothing to aggregate). Super-admin only, same guard as the rest of
-- `0027_surveys.sql`.

create or replace function public.admin_get_survey_results(_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _survey record;
begin
  if not public._is_super_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  select * into _survey from public.surveys where id = _id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  return jsonb_build_object(
    'status', 'ok',
    'survey', jsonb_build_object(
      'id', _survey.id,
      'title', _survey.title,
      'points', _survey.points,
      'response_count', (select count(*) from public.survey_responses where survey_id = _id)
    ),
    'questions', coalesce(
      (
        select jsonb_agg(row_to_json(q) order by q.sort_order)
        from (
          select
            sq.id,
            sq.question_type,
            sq.prompt,
            sq.sort_order,
            sq.rating_max,
            case when sq.question_type in ('single_choice', 'multi_choice') then (
              select jsonb_agg(
                jsonb_build_object(
                  'label', o.label,
                  'count', (
                    select count(*)
                    from public.survey_answers a
                    where a.question_id = sq.id
                      and a.answer ? 'selected'
                      and exists (
                        select 1 from jsonb_array_elements_text(a.answer->'selected') val
                        where val = o.id::text
                      )
                  )
                )
                order by o.sort_order
              )
              from public.survey_question_options o
              where o.question_id = sq.id
            ) end as options,
            case when sq.question_type = 'rating' then (
              select jsonb_build_object(
                'average', round(avg((a.answer->>'rating')::numeric), 2),
                'distribution', (
                  select jsonb_agg(
                    jsonb_build_object(
                      'value', v.value,
                      'count', (
                        select count(*) from public.survey_answers a2
                        where a2.question_id = sq.id and (a2.answer->>'rating')::int = v.value
                      )
                    )
                    order by v.value
                  )
                  from generate_series(1, coalesce(sq.rating_max, 5)) as v(value)
                )
              )
              from public.survey_answers a
              where a.question_id = sq.id and a.answer ? 'rating'
            ) end as rating,
            case when sq.question_type = 'text' then (
              select jsonb_agg(a.answer->>'text' order by a.id)
              from public.survey_answers a
              where a.question_id = sq.id and a.answer ? 'text'
            ) end as texts
          from public.survey_questions sq
          where sq.survey_id = _id
        ) q
      ),
      '[]'::jsonb
    )
  );
end;
$$;

grant execute on function public.admin_get_survey_results(uuid) to authenticated;
