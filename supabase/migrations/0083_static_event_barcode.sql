-- A permanent, printable attendance barcode, alongside the rotating one.
--
-- The rotating QR (`start_event_qr`) issues a token that expires in seconds,
-- which is the right design for a screen a host holds up and the wrong one for
-- a poster on a wall. This adds a second token per event that never expires,
-- so it can be printed once and scanned all day.
--
-- The important part of the design is what it does NOT touch:
--
--   * `scan_event_attendance` is unchanged. It already resolves a token out of
--     `event_qr_tokens`, checks the event's `qr_enabled` switch, refuses a
--     second scan by the same student, handles the walk-up registration case
--     and awards points. A static token is just a row in that same table with
--     no expiry, so every one of those behaviours applies to it for free.
--   * `start_event_qr` is unchanged, so the rotating barcode behaves exactly
--     as before.
--   * The mobile scanner is unchanged. It already sends `c2c:event:<token>`;
--     a static token is the same shape.
--
-- That leaves one real risk. `start_event_qr` lives only in the live database
-- (noted in 0062), so this file cannot see whether it purges old tokens for an
-- event before issuing a fresh one. If it does, opening the rotating QR would
-- silently destroy the printed poster's token — the worst possible failure,
-- because the poster keeps existing and simply stops working. Section 3 makes
-- that impossible without needing to read that function.
--
-- Admin-only: the three RPCs below all check `is_admin()`. Hosts and group
-- managers keep the rotating QR and get nothing here, per spec.

-- ---------------------------------------------------------------------------
-- 1. Mark which tokens are permanent
-- ---------------------------------------------------------------------------
alter table public.event_qr_tokens
  add column if not exists is_static boolean not null default false;

comment on column public.event_qr_tokens.is_static is
  'True for a printed, non-rotating attendance barcode. Such rows never '
  'expire and are protected from deletion by trg_protect_static_qr_tokens.';

-- One permanent token per (event, session). The partial index is what makes
-- "generate" idempotent rather than a way to accumulate posters that all work.
create unique index if not exists event_qr_tokens_one_static_per_scope
  on public.event_qr_tokens (event_id, coalesce(session_id, '00000000-0000-0000-0000-000000000000'::uuid))
  where is_static;

-- ---------------------------------------------------------------------------
-- 2. Generate / read
-- ---------------------------------------------------------------------------
-- The token is a random uuid, never the event id — a printed code that encoded
-- the event id would let anyone who photographed one poster derive the code for
-- any other event.
--
-- Returning the existing token rather than minting a second one matters: an
-- admin who presses the button twice must not invalidate the poster already on
-- the wall.
create or replace function public.admin_create_static_event_qr(
  _event_id   uuid,
  _session_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  _token uuid;
begin
  if not public.is_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if not exists (select 1 from public.events where id = _event_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  if _session_id is not null and not exists (
    select 1 from public.event_sessions
    where id = _session_id and event_id = _event_id
  ) then
    return jsonb_build_object('status', 'not_found');
  end if;

  select t.token into _token
  from public.event_qr_tokens t
  where t.event_id = _event_id
    and t.session_id is not distinct from _session_id
    and t.is_static
  limit 1;

  if _token is not null then
    return jsonb_build_object('status', 'ok', 'token', _token, 'created', false);
  end if;

  _token := gen_random_uuid();

  -- 'infinity' rather than a far-future date, so `now() > expires_at` in
  -- `scan_event_attendance` is false forever rather than until some date
  -- nobody will be around to notice.
  insert into public.event_qr_tokens (token, event_id, session_id, issued_at, expires_at, is_static)
  values (_token, _event_id, _session_id, now(), 'infinity'::timestamptz, true);

  return jsonb_build_object('status', 'ok', 'token', _token, 'created', true);
end;
$$;

revoke all on function public.admin_create_static_event_qr(uuid, uuid) from public;
grant execute on function public.admin_create_static_event_qr(uuid, uuid) to authenticated;

create or replace function public.admin_get_static_event_qr(
  _event_id   uuid,
  _session_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  _row public.event_qr_tokens%rowtype;
begin
  if not public.is_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  select * into _row
  from public.event_qr_tokens
  where event_id = _event_id
    and session_id is not distinct from _session_id
    and is_static
  limit 1;

  if not found then
    return jsonb_build_object('status', 'none');
  end if;

  return jsonb_build_object(
    'status',    'ok',
    'token',     _row.token,
    'issued_at', _row.issued_at
  );
end;
$$;

revoke all on function public.admin_get_static_event_qr(uuid, uuid) from public;
grant execute on function public.admin_get_static_event_qr(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. A printed token cannot be deleted by accident
-- ---------------------------------------------------------------------------
-- Cancels any DELETE of a static row unless the revoke function below has set
-- the escape hatch for the current transaction. This is what protects the
-- poster from whatever cleanup `start_event_qr` may or may not do, without
-- this file having to read it.
--
-- Returning NULL from a BEFORE DELETE trigger silently skips that row rather
-- than raising, which is deliberate: a bulk cleanup that deletes a mix of
-- rotating and static tokens should drop the rotating ones and keep going,
-- not abort with an error that leaves the caller stuck.
create or replace function public.protect_static_qr_tokens()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if coalesce(old.is_static, false)
     and coalesce(current_setting('app.allow_static_qr_delete', true), 'off') <> 'on'
  then
    return null;
  end if;

  return old;
end;
$$;

drop trigger if exists trg_protect_static_qr_tokens on public.event_qr_tokens;
create trigger trg_protect_static_qr_tokens
  before delete on public.event_qr_tokens
  for each row
  execute function public.protect_static_qr_tokens();

-- Retiring a poster: the only supported way to remove a static token, and the
-- only caller that sets the escape hatch. Scoped to the transaction (the third
-- argument to set_config), so it cannot leak into anything else on the
-- connection.
create or replace function public.admin_revoke_static_event_qr(
  _event_id   uuid,
  _session_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.is_admin() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  perform set_config('app.allow_static_qr_delete', 'on', true);

  delete from public.event_qr_tokens
  where event_id = _event_id
    and session_id is not distinct from _session_id
    and is_static;

  perform set_config('app.allow_static_qr_delete', 'off', true);

  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.admin_revoke_static_event_qr(uuid, uuid) from public;
grant execute on function public.admin_revoke_static_event_qr(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Report
-- ---------------------------------------------------------------------------
do $$
declare
  _n int;
begin
  select count(*) into _n from public.event_qr_tokens where is_static;
  raise notice 'Static attendance barcodes: %', _n;
  raise notice 'Scanning is unchanged: scan_event_attendance resolves these from the same table.';
end $$;
