-- Let an admin or host close and reopen an event's registration by hand,
-- independently of capacity.
--
-- Today the only thing that can stop registration is `register_for_event`'s
-- capacity check (0038 → 0044 → 0069), so an event with `capacity is null`
-- accepts sign-ups forever and an event at capacity can never be nudged back
-- open for a few more places. There is no switch.
--
-- Shape of the change:
--
--   * `events.registration_closed` — one boolean, the only part of this that
--     students need to read, so it lives on the table they already select from.
--   * `event_registration_audit` — who closed/reopened it and when. A separate
--     table on purpose: `grant select` on a table is all-or-nothing, so audit
--     columns added to `events` would be readable by every student along with
--     the rest of the row. The spec says this is admin-panel-only information,
--     so it goes somewhere students have no read access to at all. Being a log
--     rather than two pairs of columns also means a second close/reopen cycle
--     doesn't overwrite the first.
--   * `register_for_event` grows a gate that refuses while closed, ahead of the
--     capacity check, so a manual closure overrides capacity rather than
--     competing with it.
--
-- Depends on 0069 (`event_is_visible_to`) — the function body below keeps that
-- migration's visibility guard, so running this one alone would drop it. Run in
-- order.
--
-- Backward compatible: the column defaults to false, so every existing event
-- stays open and behaves exactly as it does now until someone closes it.

-- ---------------------------------------------------------------------------
-- 1. The flag
-- ---------------------------------------------------------------------------
alter table public.events
  add column if not exists registration_closed boolean not null default false;

comment on column public.events.registration_closed is
  'Manually set by an admin/host via set_event_registration_closed(). When '
  'true, register_for_event refuses regardless of capacity. Audit trail of who '
  'changed it lives in event_registration_audit.';

-- ---------------------------------------------------------------------------
-- 2. The audit log
-- ---------------------------------------------------------------------------
create table if not exists public.event_registration_audit (
  id         uuid primary key default gen_random_uuid(),
  event_id   uuid not null references public.events (id) on delete cascade,
  -- 'closed' | 'reopened'
  action     text not null check (action in ('closed', 'reopened')),
  actor_id   uuid references auth.users (id) on delete set null,
  -- Snapshot of the actor's display name at the time. Denormalised on purpose:
  -- an audit record that turns into "unknown" because the account was later
  -- deleted or renamed has lost the thing it existed to record.
  actor_name text,
  created_at timestamptz not null default now()
);

create index if not exists event_registration_audit_event_idx
  on public.event_registration_audit (event_id, created_at desc);

-- Table-level privileges. No insert/update/delete to `authenticated`: the only
-- writer is the security-definer RPC below, so the log can't be forged or
-- rewritten from a client even by an admin. SELECT is granted but still gated
-- by the RLS policy that follows.
grant select on public.event_registration_audit to authenticated;

alter table public.event_registration_audit enable row level security;

-- Only people who run the event may read its audit trail. Students get nothing
-- — not an empty list of their own rows, no rows at all.
drop policy if exists event_registration_audit_select_managers
  on public.event_registration_audit;
create policy event_registration_audit_select_managers
  on public.event_registration_audit
  for select
  to authenticated
  using (public.can_manage_event(event_id));

-- ---------------------------------------------------------------------------
-- 3. Close / reopen
-- ---------------------------------------------------------------------------
-- Gated on `can_manage_event` (0062), so admins plus the event's creator and
-- co-hosts — the same set that may edit the event, run its attendance and see
-- its registrants. A plain student calling this gets 'forbidden', not a
-- permission error.
create or replace function public.set_event_registration_closed(
  _event_id uuid,
  _closed   boolean
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _current boolean;
  _name    text;
begin
  if _closed is null then
    return jsonb_build_object('status', 'invalid');
  end if;

  select e.registration_closed into _current
  from public.events e
  where e.id = _event_id;

  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public.can_manage_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  -- Already in the requested state: report success without writing an audit
  -- row. A double-click shouldn't produce two "closed by" entries one second
  -- apart, and the end state is what the caller asked for either way.
  if coalesce(_current, false) = _closed then
    return jsonb_build_object('status', 'ok', 'closed', _closed, 'changed', false);
  end if;

  select coalesce(nullif(btrim(p.full_name), ''), p.email)
    into _name
  from public.profiles p
  where p.id = auth.uid();

  update public.events
     set registration_closed = _closed
   where id = _event_id;

  insert into public.event_registration_audit (event_id, action, actor_id, actor_name)
  values (
    _event_id,
    case when _closed then 'closed' else 'reopened' end,
    auth.uid(),
    _name
  );

  return jsonb_build_object('status', 'ok', 'closed', _closed, 'changed', true);
end;
$$;

revoke all on function public.set_event_registration_closed(uuid, boolean) from public;
grant execute on function public.set_event_registration_closed(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Read the state + audit trail
-- ---------------------------------------------------------------------------
-- One call for everything the admin panel's registration card shows: the
-- current state, the live registered count and capacity (so the card can
-- explain *why* registration is closed — by hand, or because it filled up),
-- and the most recent close/reopen with who did it.
--
-- Returns a null-ish object rather than erroring for a caller who doesn't
-- manage the event, matching how `admin_list_event_registrants` returns '[]'.
create or replace function public.admin_get_event_registration_state(
  _event_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  _event      public.events%rowtype;
  _registered int;
  _closed_row public.event_registration_audit%rowtype;
  _reopen_row public.event_registration_audit%rowtype;
begin
  select * into _event from public.events where id = _event_id;

  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  if not public.can_manage_event(_event_id) then
    return jsonb_build_object('status', 'forbidden');
  end if;

  select count(*) into _registered
  from public.event_registrations
  where event_id = _event_id and status = 'registered';

  select * into _closed_row
  from public.event_registration_audit
  where event_id = _event_id and action = 'closed'
  order by created_at desc
  limit 1;

  select * into _reopen_row
  from public.event_registration_audit
  where event_id = _event_id and action = 'reopened'
  order by created_at desc
  limit 1;

  return jsonb_build_object(
    'status',             'ok',
    'closed',             coalesce(_event.registration_closed, false),
    'capacity',           _event.capacity,
    'registered',         _registered,
    -- True when capacity alone would stop registration. Distinct from
    -- `closed`, so the UI can say "full" and "closed by hand" separately
    -- instead of guessing which one the student is hitting.
    'at_capacity',        _event.capacity is not null and _registered >= _event.capacity,
    'closed_at',          _closed_row.created_at,
    'closed_by_id',       _closed_row.actor_id,
    'closed_by_name',     _closed_row.actor_name,
    'reopened_at',        _reopen_row.created_at,
    'reopened_by_id',     _reopen_row.actor_id,
    'reopened_by_name',   _reopen_row.actor_name,
    'history',            coalesce(
      (
        select jsonb_agg(jsonb_build_object(
          'action',     a.action,
          'at',         a.created_at,
          'actor_id',   a.actor_id,
          'actor_name', a.actor_name
        ) order by a.created_at desc)
        from public.event_registration_audit a
        where a.event_id = _event_id
      ),
      '[]'::jsonb
    )
  );
end;
$$;

revoke all on function public.admin_get_event_registration_state(uuid) from public;
grant execute on function public.admin_get_event_registration_state(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Registration honours the switch
-- ---------------------------------------------------------------------------
-- 0069's body, plus the closure gate. Placed BEFORE the capacity check so a
-- manual closure overrides capacity rather than racing it: an unlimited event
-- can be closed, and a full event that gets reopened is refused by the
-- capacity check below until someone raises the cap — which is the honest
-- answer, since reopening doesn't create places.
create or replace function public.register_for_event(_event_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  _event public.events%rowtype;
  _registered_count int;
  _code text;
begin
  select * into _event from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'event_not_found');
  end if;

  if _event.approval_status <> 'approved' then
    return jsonb_build_object('status', 'not_published');
  end if;

  -- From 0069.
  if not public.event_is_visible_to(_event_id, auth.uid()) then
    return jsonb_build_object('status', 'not_visible');
  end if;

  if now() > _event.ends_at then
    return jsonb_build_object('status', 'ended');
  end if;

  if exists (
    select 1 from public.event_registrations
    where event_id = _event_id and user_id = auth.uid() and status = 'registered'
  ) then
    return jsonb_build_object('status', 'already');
  end if;

  -- New in 0070.
  if coalesce(_event.registration_closed, false) then
    return jsonb_build_object('status', 'registration_closed');
  end if;

  if _event.capacity is not null then
    select count(*) into _registered_count
    from public.event_registrations
    where event_id = _event_id and status = 'registered';

    if _registered_count >= _event.capacity then
      return jsonb_build_object('status', 'full');
    end if;
  end if;

  loop
    _code := encode(gen_random_bytes(9), 'hex');
    exit when not exists (select 1 from public.event_registrations where code = _code);
  end loop;

  insert into public.event_registrations (event_id, user_id, status, registered_at, code)
  values (_event_id, auth.uid(), 'registered', now(), _code)
  on conflict (event_id, user_id)
  do update set status = 'registered', registered_at = now();

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.register_for_event(uuid) to authenticated;
