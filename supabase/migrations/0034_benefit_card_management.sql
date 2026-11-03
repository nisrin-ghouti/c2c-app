-- Closes three gaps in digital-card management:
-- 1. Manual-code redemption existed but nothing ever showed the student a
--    legible code — the QR only ever encoded a URL with a 24-char hex
--    token, never displayed as text anywhere. Adds a short numeric
--    `redemption_code`, generated alongside the token, matched by both
--    redeem RPCs.
-- 2. No way for an admin to resend or revoke a specific card.
-- 3. Revoking an unredeemed card now refunds the points automatically.

alter table public.digital_cards add column if not exists redemption_code text;

create or replace function public.generate_digital_card_code()
returns text
language plpgsql
as $$
declare
  _code text;
begin
  loop
    _code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (select 1 from public.digital_cards where redemption_code = _code);
  end loop;
  return _code;
end;
$$;

-- Backfill existing cards so history stays consistent.
update public.digital_cards
set redemption_code = public.generate_digital_card_code()
where redemption_code is null;

alter table public.digital_cards alter column redemption_code set not null;
alter table public.digital_cards add constraint digital_cards_redemption_code_key unique (redemption_code);

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

  select coalesce(sum(amount), 0) into _balance from point_transactions where user_id = auth.uid();
  if _balance < _benefit.point_cost then
    return jsonb_build_object('status', 'insufficient_points');
  end if;

  insert into point_transactions (user_id, amount, reason, metadata)
  values (auth.uid(), -_benefit.point_cost, 'benefit_redeem', jsonb_build_object('benefit_id', _benefit_id));

  _qr_token := encode(gen_random_bytes(12), 'hex');
  _code := public.generate_digital_card_code();

  insert into digital_cards (benefit_id, user_id, qr_token, redemption_code, points_spent)
  values (_benefit_id, auth.uid(), _qr_token, _code, _benefit.point_cost)
  returning id into _card_id;

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

create or replace function public.redeem_digital_card(_token text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _card digital_cards%rowtype;
  _title text;
begin
  if not exists (select 1 from user_roles where user_id = auth.uid() and role in ('host', 'admin')) then
    return jsonb_build_object('status', 'invalid');
  end if;

  select * into _card from digital_cards
  where qr_token = _token or redemption_code = _token;
  if not found then
    return jsonb_build_object('status', 'invalid');
  end if;
  if _card.status = 'redeemed' then
    return jsonb_build_object('status', 'already_redeemed');
  end if;

  update digital_cards set status = 'redeemed', redeemed_at = now(), redeemed_by = auth.uid()
  where id = _card.id;

  select title into _title from benefits where id = _card.benefit_id;

  return jsonb_build_object('status', 'ok', 'title', _title);
end;
$$;

create or replace function public.redeem_digital_card_public(_token text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _card digital_cards%rowtype;
  _title text;
begin
  select * into _card from digital_cards
  where qr_token = _token or redemption_code = _token;
  if not found then
    return jsonb_build_object('status', 'invalid');
  end if;
  if _card.status = 'redeemed' then
    return jsonb_build_object('status', 'already_redeemed');
  end if;

  update digital_cards set status = 'redeemed', redeemed_at = now()
  where id = _card.id;

  select title into _title from benefits where id = _card.benefit_id;

  return jsonb_build_object('status', 'ok', 'title', _title);
end;
$$;

-- Admin: every card issued for a benefit (active and redeemed), not just
-- successful redemptions — the "who has an active card, who's used it"
-- view a benefit's management dialog needs.
create or replace function public.admin_list_benefit_cards(_benefit_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.is_admin() then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'card_id', c.id,
        'user_id', p.id,
        'full_name', p.full_name,
        'email', p.email,
        'gender', p.gender,
        'redemption_code', c.redemption_code,
        'points_spent', c.points_spent,
        'is_redeemed', c.status = 'redeemed',
        'redeemed_at', c.redeemed_at,
        'created_at', c.created_at
      ) order by c.created_at desc)
      from public.digital_cards c
      join public.profiles p on p.id = c.user_id
      where c.benefit_id = _benefit_id
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.admin_list_benefit_cards(uuid) to authenticated;

-- Admin: nudge the student with a notification carrying the benefit +
-- code again (their existing card is untouched — this doesn't reissue
-- anything, just resurfaces what they already have).
alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array[
    'points_earned', 'new_message', 'meeting_proposal', 'event_pending_approval',
    'event_published', 'benefit_published', 'report_submitted', 'event_decision',
    'group_meeting_pending', 'benefit_redeemed', 'benefit_card_resent'
  ]));

create or replace function public.admin_resend_benefit_card(_card_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _card digital_cards%rowtype;
  _title text;
begin
  if not public.is_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  select * into _card from public.digital_cards where id = _card_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  select title into _title from public.benefits where id = _card.benefit_id;

  insert into public.notifications (user_id, type, data)
  values (
    _card.user_id,
    'benefit_card_resent',
    jsonb_build_object(
      'card_id', _card.id,
      'benefit_id', _card.benefit_id,
      'benefit_title', _title,
      'redemption_code', _card.redemption_code
    )
  );

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.admin_resend_benefit_card(uuid) to authenticated;

-- Admin: remove a card from a student's wallet. Refunds the points spent
-- only if it hasn't been redeemed yet — a redeemed card already delivered
-- the real-world benefit, so there's nothing to refund.
create or replace function public.admin_revoke_benefit_card(_card_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _card digital_cards%rowtype;
begin
  if not public.is_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  select * into _card from public.digital_cards where id = _card_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  if _card.status <> 'redeemed' and _card.points_spent > 0 then
    insert into public.point_transactions (user_id, amount, reason, metadata)
    values (
      _card.user_id,
      _card.points_spent,
      'benefit_revoke_refund',
      jsonb_build_object('card_id', _card.id, 'benefit_id', _card.benefit_id)
    );
  end if;

  delete from public.digital_cards where id = _card_id;

  return jsonb_build_object('status', 'ok', 'refunded', _card.status <> 'redeemed');
end;
$$;

grant execute on function public.admin_revoke_benefit_card(uuid) to authenticated;

-- Admin: mark a card redeemed directly (the "Redeem Benefit" button),
-- without needing to scan — same effect as `redeem_digital_card` but
-- keyed by card id, since the admin already has the row in front of them.
create or replace function public.admin_redeem_benefit_card(_card_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _card digital_cards%rowtype;
begin
  if not public.is_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  select * into _card from public.digital_cards where id = _card_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;
  if _card.status = 'redeemed' then
    return jsonb_build_object('status', 'already_redeemed');
  end if;

  update public.digital_cards set status = 'redeemed', redeemed_at = now(), redeemed_by = auth.uid()
  where id = _card_id;

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.admin_redeem_benefit_card(uuid) to authenticated;

-- Student's own wallet list also needs the new column — explicit RETURNS
-- TABLE signature means it must be dropped and recreated, not just replaced.
drop function if exists public.list_my_digital_cards();
create function public.list_my_digital_cards()
returns table(id uuid, benefit_id uuid, title text, description text, category text, image_url text, partner_business_name text, qr_token text, redemption_code text, status text, points_spent integer, redeemed_at timestamp with time zone, created_at timestamp with time zone)
language sql
security definer
set search_path to 'public'
as $$
  select dc.id, dc.benefit_id, b.title, b.description, b.category,
         b.image_url, b.partner_business_name, dc.qr_token, dc.redemption_code, dc.status,
         dc.points_spent, dc.redeemed_at, dc.created_at
  from digital_cards dc
  join benefits b on b.id = dc.benefit_id
  where dc.user_id = auth.uid()
  order by dc.created_at desc;
$$;
