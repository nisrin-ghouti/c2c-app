-- Surveys currently generate zero notifications when published — add the
-- same "published" fan-out pattern already used for events/benefits
-- (0014_notification_triggers.sql).

alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array[
    'points_earned', 'new_message', 'meeting_proposal', 'event_pending_approval',
    'event_published', 'benefit_published', 'report_submitted', 'event_decision',
    'group_meeting_pending', 'benefit_redeemed', 'benefit_card_resent',
    'survey_published'
  ]));

create or replace function public.notify_survey_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and old.is_published is not distinct from new.is_published then
    return new;
  end if;

  if new.is_published is not true then
    return new;
  end if;

  perform public.notify_all_students(
    'survey_published',
    jsonb_build_object(
      'survey_id', new.id,
      'title',     new.title,
      'points',    new.points
    ),
    new.created_by
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_survey_published on public.surveys;
create trigger trg_notify_survey_published
  after insert or update of is_published on public.surveys
  for each row
  execute function public.notify_survey_published();
