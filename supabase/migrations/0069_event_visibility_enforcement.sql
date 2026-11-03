-- Make `events.visibility` actually mean something.
--
-- The column has been written since the beginning and read by nothing: grep
-- the whole migration series and `visibility` appears only in insert/update
-- payloads and in `event_visibility_targets` housekeeping. No RLS policy, no
-- RPC and no client query has ever filtered on it. The practical result is
-- that every approved event is visible to every signed-in user regardless of
-- what the host picked — "Only me" and "Specific faculties" included, which is
-- why the admin console is dropping the (equally non-functional) "Specific
-- groups" option rather than keeping a fourth setting that does nothing.
--
-- This migration supplies the missing enforcement in two places:
--
--   1. A RESTRICTIVE RLS policy on `events`, so the rows themselves stop being
--      readable by people the event isn't for. Restrictive is the important
--      word: restrictive policies AND with the existing permissive ones, so
--      this tightens SELECT without this file having to know (or rewrite) the
--      permissive policy that predates the migration series and lives only in
--      the live database. Nothing is dropped; the existing policy keeps
--      deciding who *may* read, and this one subtracts who may not.
--
--   2. `register_for_event`, so a stale or hand-rolled client can't register
--      for an event it shouldn't have been offered. 0070 re-declares this same
--      function to add the manual-close gate — run these in order.
--
-- Deliberately NOT enforced against: 'specific_groups'. That value is being
-- retired from the admin UI, and the events already carrying it have been
-- visible to everyone for their whole life. Treating it as a restriction now
-- would retroactively hide live events that students can currently see, which
-- is a data-visibility regression dressed up as a bug fix. It is mapped to
-- "everyone" below, which is exactly how it has always behaved.
--
-- To undo everything here instantly:
--   drop policy if exists events_visibility_restrictive on public.events;

-- ---------------------------------------------------------------------------
-- 1. The predicate
-- ---------------------------------------------------------------------------
-- `security definer` so it can be used inside an RLS policy on `events` while
-- reading `profiles`, `event_visibility_targets` and `host_event_access`
-- without dragging those tables' own policies into the check — the same
-- recursion trap 0004 untangled and 0062 avoided the same way.
--
-- Written so that only two visibility values can ever restrict anything and
-- everything else falls through to visible. A bug in this function must not be
-- able to empty the events list app-wide, so "unrecognised" means "show it".
create or replace function public.event_is_visible_to(
  _event_id uuid,
  _user_id  uuid default auth.uid()
)
returns boolean
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  _visibility text;
begin
  select e.visibility into _visibility
  from public.events e
  where e.id = _event_id;

  -- No such event: let the other policies answer, don't invent a denial.
  if not found then
    return true;
  end if;

  -- Anyone who runs the event always sees it — creator, co-host, or any
  -- admin. This is also what makes 'only_me' work: the check below denies
  -- everyone else, and this clause is the "me" half.
  if _user_id is not null and public.can_manage_event(_event_id, _user_id) then
    return true;
  end if;

  case coalesce(_visibility, 'everyone')

    when 'only_me' then
      -- Managers already returned true above, so reaching here means the
      -- viewer is not one.
      return false;

    when 'specific_faculties' then
      if _user_id is null then
        return false;
      end if;

      -- An event marked faculty-restricted with no targets stored would
      -- otherwise be visible to nobody at all — including, after a partial
      -- save, its own intended audience. Treat "no targets" as unrestricted
      -- rather than silently burying the event.
      if not exists (
        select 1
        from public.event_visibility_targets t
        where t.event_id = _event_id
          and t.target_type = 'faculty'
      ) then
        return true;
      end if;

      return exists (
        select 1
        from public.profiles p
        join public.event_visibility_targets t
          on t.event_id = _event_id
         and t.target_type = 'faculty'
         and (
           -- `faculties` is the current multi-value column (0001); `faculty`
           -- is the legacy single-value one it was backfilled from, still
           -- populated for existing consumers. Match either.
           t.target_value = any (coalesce(p.faculties, '{}'::text[]))
           or t.target_value = p.faculty
         )
        where p.id = _user_id
      );

    else
      -- 'everyone', 'specific_groups' (see the header note), and anything
      -- unrecognised.
      return true;

  end case;

  -- Unreachable: every branch above returns. Present so the function can
  -- never fall off the end and raise "control reached end of function
  -- without RETURN" — which, for a predicate wired into an RLS policy,
  -- would take the events list down rather than degrade.
  return true;
end;
$$;

revoke all on function public.event_is_visible_to(uuid, uuid) from public;
grant execute on function public.event_is_visible_to(uuid, uuid) to authenticated, anon;

-- ---------------------------------------------------------------------------
-- 2. Row-level enforcement
-- ---------------------------------------------------------------------------
-- Restrictive, so it ANDs with whatever permissive SELECT policy the project
-- already has instead of replacing it. Applied to the two app-facing roles
-- only: every admin RPC is `security definer` and owned by a role that
-- bypasses RLS, so the admin console, the Host Panel and the notification
-- triggers are all unaffected by this.
alter table public.events enable row level security;

drop policy if exists events_visibility_restrictive on public.events;
create policy events_visibility_restrictive
  on public.events
  as restrictive
  for select
  to authenticated, anon
  using (public.event_is_visible_to(id));

-- ---------------------------------------------------------------------------
-- 3. Registration honours visibility too
-- ---------------------------------------------------------------------------
-- RLS hides the row from a listing, but `register_for_event` is
-- `security definer` and reads `events` directly, so it would happily register
-- someone for an event they can no longer see if they still had the id. Body
-- is 0044's verbatim, plus the one new guard.
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

  -- New in 0069. Returns the same shape as every other refusal; a client that
  -- doesn't know this status yet falls through to its generic error, which is
  -- the correct outcome either way.
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

  if _event.capacity is not null then
    select count(*) into _registered_count
    from public.event_registrations
    where event_id = _event_id and status = 'registered';

    if _registered_count >= _event.capacity then
      return jsonb_build_object('status', 'full');
    end if;
  end if;

  -- Only needed on first-time insert; the ON CONFLICT UPDATE path below
  -- reuses whatever code the row already has.
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

-- ---------------------------------------------------------------------------
-- 4. Performance note
-- ---------------------------------------------------------------------------
-- The policy calls `event_is_visible_to` once per candidate row, and that in
-- turn calls `can_manage_event`. For an admin this short-circuits on the first
-- `is_admin()` check, and for a student the expensive path is only taken for
-- events actually marked `specific_faculties`. At this project's scale (a few
-- hundred events) that is fine; if the events table grows by orders of
-- magnitude, the index below is what the faculty lookup wants.
create index if not exists event_visibility_targets_event_type_idx
  on public.event_visibility_targets (event_id, target_type);

-- ---------------------------------------------------------------------------
-- 5. What the existing permissive policy looks like
-- ---------------------------------------------------------------------------
-- Printed rather than modified. If any permissive SELECT policy on `events`
-- targets a role NOT covered above, the restrictive policy won't apply to it
-- and that role keeps seeing everything. Same reporting approach as 0062's
-- creator-only-guard audit.
do $$
declare
  _p record;
begin
  raise notice 'Permissive SELECT policies on public.events:';
  for _p in
    select policyname, roles::text as roles, qual
    from pg_policies
    where schemaname = 'public'
      and tablename = 'events'
      and permissive = 'PERMISSIVE'
      and cmd in ('SELECT', 'ALL')
  loop
    raise notice '  % — roles=% using=%', _p.policyname, _p.roles, _p.qual;
  end loop;
end $$;
