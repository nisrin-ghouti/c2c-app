-- Notify a student (in-app + push, via the existing notifications->send-push
-- webhook) when a partner redeems their digital card through the public
-- web confirmation page (the `redeem-benefit` Edge Function).
--
-- Fires on the transition of `digital_cards.status` -> 'redeemed', which is
-- exactly what `redeem_digital_card()` sets regardless of who/what called it
-- (in-app admin scanner or the new public web page), so this covers both
-- paths without touching that function.

-- 1. Allow the new type label -----------------------------------------------
do $$
declare
  type_name text;
  con_name  text;
begin
  select t.typname into type_name
  from pg_attribute a
  join pg_type t on t.oid = a.atttypid
  where a.attrelid = 'public.notifications'::regclass
    and a.attname  = 'type'
    and a.attnum   > 0;

  if type_name is distinct from 'text' and type_name is distinct from 'varchar' then
    execute format('alter type public.%I add value if not exists %L', type_name, 'benefit_redeemed');
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
        'group_meeting_pending',
        'benefit_redeemed'
      ));
  end if;
end
$$;

-- 2. Trigger: digital_cards.status -> 'redeemed' -----------------------------
create or replace function public.notify_benefit_redeemed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status is not distinct from new.status then
    return new;
  end if;

  if new.status <> 'redeemed' then
    return new;
  end if;

  insert into public.notifications (user_id, type, data)
  values (
    new.user_id,
    'benefit_redeemed',
    jsonb_build_object(
      'digital_card_id', new.id,
      'benefit_id',      new.benefit_id,
      'title',           new.title,
      'business',        new.partner_business_name
    )
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_benefit_redeemed on public.digital_cards;
create trigger trg_notify_benefit_redeemed
  after update of status on public.digital_cards
  for each row
  execute function public.notify_benefit_redeemed();
