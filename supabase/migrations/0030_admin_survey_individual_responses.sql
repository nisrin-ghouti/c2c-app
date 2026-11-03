-- Per-student answer breakdown — the aggregated view in 0029 answers "what
-- did people say overall", this answers "who said what". Same super-admin
-- guard, same survey. Answer text is rendered readable server-side (option
-- labels joined, rating shown as "n / max") so the client doesn't need to
-- re-derive it from option ids.

create or replace function public.admin_get_survey_responses(_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public._is_super_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if not exists (select 1 from public.surveys where id = _id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  return jsonb_build_object(
    'status', 'ok',
    'responses', coalesce(
      (
        select jsonb_agg(row_to_json(r) order by r.submitted_at desc)
        from (
          select
            resp.id as response_id,
            resp.user_id,
            coalesce(p.full_name, '') as name,
            p.email,
            resp.submitted_at,
            resp.points_awarded,
            (
              select jsonb_agg(
                jsonb_build_object(
                  'question_id', sq.id,
                  'prompt', sq.prompt,
                  'question_type', sq.question_type,
                  'text', case sq.question_type
                    when 'text' then a.answer->>'text'
                    when 'rating' then case when a.answer ? 'rating' then
                      (a.answer->>'rating') || coalesce(' / ' || sq.rating_max::text, '')
                    end
                    else (
                      select string_agg(o.label, ', ' order by o.sort_order)
                      from public.survey_question_options o
                      where o.question_id = sq.id
                        and o.id::text in (
                          select jsonb_array_elements_text(coalesce(a.answer->'selected', '[]'::jsonb))
                        )
                    )
                  end
                )
                order by sq.sort_order
              )
              from public.survey_questions sq
              left join public.survey_answers a
                on a.question_id = sq.id and a.response_id = resp.id
              where sq.survey_id = _id
            ) as answers
          from public.survey_responses resp
          left join public.profiles p on p.id = resp.user_id
          where resp.survey_id = _id
        ) r
      ),
      '[]'::jsonb
    )
  );
end;
$$;

grant execute on function public.admin_get_survey_responses(uuid) to authenticated;
