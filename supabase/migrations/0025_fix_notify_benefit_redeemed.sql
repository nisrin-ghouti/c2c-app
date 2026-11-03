-- Fix `notify_benefit_redeemed()` from migration 0023: it referenced
-- new.title / new.partner_business_name, which don't exist on
-- digital_cards (those live on benefits, joined via benefit_id) — every
-- redemption update was failing with "record new has no field title".
create or replace function public.notify_benefit_redeemed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  _title    text;
  _business text;
begin
  if old.status is not distinct from new.status then
    return new;
  end if;

  if new.status <> 'redeemed' then
    return new;
  end if;

  select b.title, b.partner_business_name
  into _title, _business
  from public.benefits b
  where b.id = new.benefit_id;

  insert into public.notifications (user_id, type, data)
  values (
    new.user_id,
    'benefit_redeemed',
    jsonb_build_object(
      'digital_card_id', new.id,
      'benefit_id',      new.benefit_id,
      'title',           _title,
      'business',        _business
    )
  );
  return new;
end;
$$;
