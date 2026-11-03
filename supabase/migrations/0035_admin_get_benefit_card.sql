-- One card's full detail — benefit + student + card, joined — backing the
-- admin panel's "Student Benefit Card" detail page (one call instead of
-- fetching the whole list and filtering client-side).

create or replace function public.admin_get_benefit_card(_card_id uuid)
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

  return jsonb_build_object(
    'status', 'ok',
    'card', (
      select jsonb_build_object(
        'card_id', c.id,
        'benefit_id', b.id,
        'benefit_title', b.title,
        'benefit_description', b.description,
        'benefit_category', b.category,
        'benefit_location', b.location,
        'benefit_how_to_redeem', b.how_to_redeem,
        'benefit_active', b.active,
        'partner_business_name', b.partner_business_name,
        'user_id', p.id,
        'full_name', p.full_name,
        'email', p.email,
        'gender', p.gender,
        'student_id', p.student_id,
        'avatar_url', p.avatar_url,
        'redemption_code', c.redemption_code,
        'points_spent', c.points_spent,
        'is_redeemed', c.status = 'redeemed',
        'redeemed_at', c.redeemed_at,
        'created_at', c.created_at
      )
      from public.digital_cards c
      join public.benefits b on b.id = c.benefit_id
      join public.profiles p on p.id = c.user_id
      where c.id = _card_id
    )
  );
end;
$$;

grant execute on function public.admin_get_benefit_card(uuid) to authenticated;
