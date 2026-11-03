-- `redeem_benefit` (0034) never checked whether the student already holds an
-- unredeemed card for the benefit — nothing stopped repeated redemption, each
-- attempt just spent more points and minted another card. Per spec, a
-- benefit must stay unavailable to a student while they have an active,
-- unused card for it, and only becomes redeemable again once that card is
-- scanned/used.
--
-- The partial unique index is the authoritative guard (safe under concurrent
-- double-taps); the explicit check in the function just turns that into a
-- clean `already_active` status instead of a raw constraint-violation error.

create unique index if not exists digital_cards_one_active_per_benefit
  on public.digital_cards (user_id, benefit_id)
  where status <> 'redeemed';

create or replace function public.redeem_benefit(_benefit_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  _benefit benefits%rowtype;
  _balance int;
  _card_id uuid;
  _qr_token text;
  _code text;
begin
  if not public.is_student_eligible(auth.uid()) then
    return jsonb_build_object('status', 'not_a_student');
  end if;

  select * into _benefit from benefits where id = _benefit_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;
  if not _benefit.active then
    return jsonb_build_object('status', 'inactive');
  end if;

  if exists (
    select 1 from digital_cards
    where user_id = auth.uid() and benefit_id = _benefit_id and status <> 'redeemed'
  ) then
    return jsonb_build_object('status', 'already_active');
  end if;

  select coalesce(sum(amount), 0) into _balance from point_transactions where user_id = auth.uid();
  if _balance < _benefit.point_cost then
    return jsonb_build_object('status', 'insufficient_points');
  end if;

  insert into point_transactions (user_id, amount, reason, metadata)
  values (auth.uid(), -_benefit.point_cost, 'benefit_redeem', jsonb_build_object('benefit_id', _benefit_id));

  _qr_token := encode(gen_random_bytes(12), 'hex');
  _code := public.generate_digital_card_code();

  -- Belt-and-suspenders against a concurrent double-tap racing past the
  -- `exists` check above: the unique index turns that into a 23505, which
  -- reads as a normal Postgres exception here rather than a points refund
  -- gap, so surface it as the same clean status instead of a 500.
  begin
    insert into digital_cards (benefit_id, user_id, qr_token, redemption_code, points_spent)
    values (_benefit_id, auth.uid(), _qr_token, _code, _benefit.point_cost)
    returning id into _card_id;
  exception when unique_violation then
    insert into point_transactions (user_id, amount, reason, metadata)
    values (auth.uid(), _benefit.point_cost, 'benefit_redeem_refund', jsonb_build_object('benefit_id', _benefit_id));
    return jsonb_build_object('status', 'already_active');
  end;

  return jsonb_build_object(
    'status', 'ok',
    'id', _card_id,
    'benefit_id', _benefit_id,
    'title', _benefit.title,
    'description', _benefit.description,
    'category', _benefit.category,
    'image_url', _benefit.image_url,
    'partner_business_name', _benefit.partner_business_name,
    'qr_token', _qr_token,
    'redemption_code', _code,
    'points_spent', _benefit.point_cost,
    'redeemed_at', null,
    'created_at', now()
  );
end;
$$;
