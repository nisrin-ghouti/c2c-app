-- Notifications: fan-out triggers for the rest of the app's important actions.
--
-- Existing (base schema / migration 0013), untouched here:
--   points_earned          -> trigger on point_transactions
--   new_message            -> trigger on chat_messages
--   meeting_proposal       -> trigger on meeting_proposals
--   event_pending_approval -> trigger on events (0013)
--
-- Added here:
--   event_published        -> every student, when an event becomes approved
--   benefit_published      -> every student, when a benefit becomes active
--   report_submitted       -> admins, when a student files a report
--   event_decision         -> the host, when their event is approved/rejected
--   group_meeting_pending  -> admins, when a group meeting awaits approval
--
-- All fan-out helpers are SECURITY DEFINER: the acting user (a student
-- publishing nothing, an admin approving) has no RLS right to write rows into
-- other people's notification feeds, and shouldn't.

-- 1. Allow the new type labels ----------------------------------------------
-- Same dual-shape handling as 0013 — `notifications.type` may be a text column
-- with a CHECK, or a Postgres enum.
do $$
declare
  type_name text;
  con_name  text;
  new_label text;
  labels text[] := array[
    'event_published',
    'benefit_published',
    'report_submitted',
    'event_decision',
    'group_meeting_pending'
  ];
begin
  select t.typname into type_name
  from pg_attribute a
  join pg_type t on t.oid = a.atttypid
  where a.attrelid = 'public.notifications'::regclass
    and a.attname  = 'type'
    and a.attnum   > 0;

  if type_name is distinct from 'text' and type_name is distinct from 'varchar' then
    foreach new_label in array labels loop
      execute format('alter type public.%I add value if not exists %L', type_name, new_label);
    end loop;
  else
    select conname into con_name
    from pg_constraint
    where conrelid = 'public.notifications'::regclass
      and contype  = 'c'
      and pg_get_constraintdef(oid) ilike '%type%';

    if con_name is not null then
      execute format('alter table public.notifications drop constraint %I', con_name);
    end if;

    alter table public.notifications
      add constraint notifications_type_check
      check (type in (
        'points_earned',
        'new_message',
        'meeting_proposal',
        'event_pending_approval',
        'event_published',
        'benefit_published',
        'report_submitted',
        'event_decision',
        'group_meeting_pending'
      ));
  end if;
end
$$;

-- 2. Shared fan-out helpers --------------------------------------------------
-- One row per student. `_except` skips the actor so nobody is notified about
-- their own action.
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

create or replace function public.notify_all_admins(
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
  select r.user_id, _type, _data
  from public.user_roles r
  where r.role = 'admin'::app_role
    and (_except is null or r.user_id <> _except);
$$;

-- 3. Event published ---------------------------------------------------------
-- Fires on the two distinct paths an event can become visible to students:
--   * INSERT already approved  — an admin's own event (auto-approved in 0013)
--   * UPDATE pending->approved — a host's event, once an admin approves it
-- Guarding on the *transition* (not just the current value) is what stops an
-- unrelated edit to an approved event from re-notifying the whole campus.
create or replace function public.notify_event_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and old.approval_status is not distinct from new.approval_status then
    return new;
  end if;

  if new.approval_status <> 'approved' then
    return new;
  end if;

  perform public.notify_all_students(
    'event_published',
    jsonb_build_object(
      'event_id',  new.id,
      'title',     new.title,
      'starts_at', new.starts_at,
      'points',    new.points
    ),
    new.created_by
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_event_published on public.events;
create trigger trg_notify_event_published
  after insert or update of approval_status on public.events
  for each row
  execute function public.notify_event_published();

-- 4. Event approved / rejected -> tell the host ------------------------------
-- The host submitted it and otherwise has to poll their own event to find out.
create or replace function public.notify_event_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.approval_status is not distinct from new.approval_status then
    return new;
  end if;

  if new.approval_status not in ('approved', 'rejected') then
    return new;
  end if;

  insert into public.notifications (user_id, type, data)
  values (
    new.created_by,
    'event_decision',
    jsonb_build_object(
      'event_id', new.id,
      'title',    new.title,
      'status',   new.approval_status,
      'reason',   new.rejection_reason
    )
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_event_decision on public.events;
create trigger trg_notify_event_decision
  after update of approval_status on public.events
  for each row
  execute function public.notify_event_decision();

-- 5. Benefit published -------------------------------------------------------
-- "Published" for a benefit means `active` — that's the flag `list_benefits`
-- filters on, so it is exactly when students can first see it.
create or replace function public.notify_benefit_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
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
    )
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_benefit_published on public.benefits;
create trigger trg_notify_benefit_published
  after insert or update of active on public.benefits
  for each row
  execute function public.notify_benefit_published();

-- 6. Report submitted -> admins ---------------------------------------------
-- Deliberately carries no reason/details in `data`: notification rows are
-- readable by their recipient and this keeps the payload minimal. Admins open
-- the reports queue for the substance.
create or replace function public.notify_report_submitted()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.notify_all_admins(
    'report_submitted',
    jsonb_build_object('report_id', new.id),
    new.reporter_id
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_report_submitted on public.reports;
create trigger trg_notify_report_submitted
  after insert on public.reports
  for each row
  execute function public.notify_report_submitted();

-- 7. Group meeting awaiting approval -> admins -------------------------------
-- Mirrors the event-approval queue; guarded with to_regclass so this migration
-- still applies cleanly if the table is named differently in your schema.
do $$
begin
  if to_regclass('public.group_meetings') is null then
    raise notice 'skipping group-meeting notification: public.group_meetings not found';
    return;
  end if;

  execute $fn$
    create or replace function public.notify_group_meeting_pending()
    returns trigger
    language plpgsql
    security definer
    set search_path = public
    as $body$
    begin
      if new.status is distinct from 'pending' then
        return new;
      end if;

      perform public.notify_all_admins(
        'group_meeting_pending',
        jsonb_build_object('group_meeting_id', new.id),
        null
      );
      return new;
    end;
    $body$;
  $fn$;

  execute 'drop trigger if exists trg_notify_group_meeting_pending on public.group_meetings';
  execute '
    create trigger trg_notify_group_meeting_pending
      after insert on public.group_meetings
      for each row
      execute function public.notify_group_meeting_pending()';
end
$$;
