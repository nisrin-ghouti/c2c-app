-- Public (no-login) variant of `redeem_digital_card` for the QR-camera ->
-- web confirmation flow (`redeem-benefit` Edge Function). The original
-- function requires the caller to hold a host/admin role via auth.uid(),
-- which only fits the in-app admin scanner. Here there is no authenticated
-- user at all (the partner never logs in) — the qr_token itself is the
-- unguessable, single-use secret that authorizes the redemption, so the
-- role check is intentionally omitted.
--
-- Locked down to service_role only: it must not be callable with the
-- public anon key, only from the Edge Function's service-role client.
create or replace function public.redeem_digital_card_public(_token text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  _card digital_cards%rowtype;
  _title text;
begin
  select * into _card from digital_cards where qr_token = _token;
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
$function$;

revoke all on function public.redeem_digital_card_public(text) from public, anon, authenticated;
grant execute on function public.redeem_digital_card_public(text) to service_role;
