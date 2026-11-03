-- Admin-facing "get one survey for editing" — `get_survey_detail` (0027)
-- enforces publish/visibility/open-window checks meant for students, which
-- would block a super admin from reviewing a draft or already-answered
-- survey. This is the unrestricted counterpart, questions + options +
-- targets included, gated on `_is_super_admin()` only.

create or replace function public.admin_get_survey(_id uuid)
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
      'id', _survey.id, 'title', _survey.title, 'description', _survey.description,
      'points', _survey.points, 'opens_at', _survey.opens_at, 'closes_at', _survey.closes_at,
      'is_published', _survey.is_published
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
          where sq.survey_id = _id
        ) q
      ),
      '[]'::jsonb
    ),
    'targets', coalesce(
      (
        select jsonb_agg(jsonb_build_object('target_type', t.target_type, 'target_value', t.target_value))
        from public.survey_targets t
        where t.survey_id = _id
      ),
      '[]'::jsonb
    )
  );
end;
$$;

grant execute on function public.admin_get_survey(uuid) to authenticated;
