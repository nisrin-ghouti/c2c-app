-- Re-assert the "new benefit" notification, and bring it in line with the
-- "new event" one.
--
-- The chain already exists: `trg_notify_benefit_published` (0014) writes a
-- `benefit_published` row, the Database Webhook on `notifications` INSERT hands
-- it to `send-push`, which has a `benefit_published` case, and the app parses,
-- renders and deep-links that type. So nothing here is new behaviour — this
-- migration exists for two reasons.
--
-- 1. REINSTALL. If 0014 never landed on this database (or the trigger was
--    dropped at some point), benefits are silent while events are not, and the
--    two are indistinguishable from the app side. Everything below is
--    `create or replace` / `drop ... if exists`, so running it is a no-op where
--    0014 is already in place and a repair where it isn't.
--
-- 2. PARITY WITH EVENTS. The event fan-out (0014) and the survey fan-out (0036)
--    both pass `created_by` as `_except`, so the person who published it isn't
--    notified about their own action. The benefit fan-out was written without
--    that argument, so an admin publishing a benefit got a "New benefit"
--    push about the benefit they had just created. `benefits.created_by`
--    exists (see 0058), so this is simply the missing argument.
--
-- "Published" for a benefit means `active` — that's the flag `list_benefits`
-- filters on, so it is exactly the moment students can first see it. A benefit
-- created with `active = false` therefore notifies when it is later switched
-- on, not at insert. That is deliberate and matches how a host's event
-- notifies on approval rather than on submission.

-- Make sure the type label is permitted before anything tries to write it.
-- Superset of 0014's and 0036's lists; re-stating it keeps this file
-- self-sufficient on a database where 0036 is missing too.
alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array[
    'points_earned', 'new_message', 'meeting_proposal', 'event_pending_approval',
    'event_published', 'benefit_published', 'report_submitted', 'event_decision',
    'group_meeting_pending', 'benefit_redeemed', 'benefit_card_resent',
    'survey_published'
  ]));

-- The fan-out helper, in case 0014 is absent entirely.
create or replace function public.notify_all_students(
  _type   text,
  _data   jsonb,
  _except uuid default null
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.notifications (user_id, type, data)
  select p.id, _type, _data
  from public.profiles p
  where _except is null or p.id <> _except;
$$;

create or replace function public.notify_benefit_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Guard on the *transition*, not the current value: without this, every
  -- later edit to an already-active benefit re-notifies the whole campus.
  -- Same rule the event trigger uses for `approval_status`.
  if tg_op = 'UPDATE' and old.active is not distinct from new.active then
    return new;
  end if;

  if new.active is not true then
    return new;
  end if;

  perform public.notify_all_students(
    'benefit_published',
    jsonb_build_object(
      'benefit_id', new.id,
      'title',      new.title,
      'points',     new.point_cost,
      'business',   new.partner_business_name
    ),
    -- The parity fix: don't notify whoever published it.
    new.created_by
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_benefit_published on public.benefits;
create trigger trg_notify_benefit_published
  after insert or update of active on public.benefits
  for each row
  execute function public.notify_benefit_published();

-- Report what's now in place, so running this in the SQL editor tells you
-- whether it was a repair or a no-op.
do $$
declare
  _installed boolean;
  _rows      bigint;
begin
  select exists (
    select 1 from pg_trigger
    where tgrelid = 'public.benefits'::regclass
      and tgname  = 'trg_notify_benefit_published'
      and not tgisinternal
  ) into _installed;

  select count(*) into _rows
  from public.notifications where type = 'benefit_published';

  raise notice 'benefit notifications: trigger installed = %, existing benefit_published rows = %',
    _installed, _rows;
  raise notice 'if that row count is 0 and events do notify, 0014 had not been applied here.';
end
$$;
