-- Admin permanent delete for a benefit, even when students already hold or
-- redeemed digital cards. Previously `delete_benefit` returned `has_cards`
-- and blocked the action; admins need to remove test / obsolete benefits
-- from the catalog and student wallets.
--
-- Mirrors `admin_revoke_benefit_card` (0034): unredeemed cards get a points
-- refund; redeemed cards are removed with no refund (the real-world benefit
-- was already delivered). Then the benefit row itself is deleted.

create or replace function public.delete_benefit(_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _card public.digital_cards%rowtype;
  _cards_deleted int := 0;
  _refunded int := 0;
begin
  if not public.is_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if not exists (select 1 from public.benefits where id = _id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  for _card in
    select * from public.digital_cards where benefit_id = _id
  loop
    if _card.status <> 'redeemed' and coalesce(_card.points_spent, 0) > 0 then
      insert into public.point_transactions (user_id, amount, reason, metadata)
      values (
        _card.user_id,
        _card.points_spent,
        'benefit_delete_refund',
        jsonb_build_object('card_id', _card.id, 'benefit_id', _card.benefit_id)
      );
      _refunded := _refunded + 1;
    end if;
  end loop;

  delete from public.digital_cards where benefit_id = _id;
  get diagnostics _cards_deleted = row_count;

  delete from public.benefits where id = _id;

  return jsonb_build_object(
    'status', 'ok',
    'cards_deleted', _cards_deleted,
    'refunded', _refunded
  );
end;
$$;

grant execute on function public.delete_benefit(uuid) to authenticated;
