-- Permanent per-student ID + manual attendance confirmation.
--
-- Purpose: when a QR can't be scanned at an event or program session, the
-- student reads out their Student ID and the host/admin types it in. This is
-- explicitly NOT for student-to-student meetings — those still require the
-- mutual QR scan, which is what makes a peer meeting attestable at all.

-- 1. The Student ID ----------------------------------------------------------
-- 10 digits, stored as text: it is an identifier to be read aloud and typed,
-- never arithmetic, and text keeps any leading zero. Unique + never reissued.
alter table public.profiles
  add column if not exists student_id text;

-- Generate-and-retry rather than a sequence: a sequence would make IDs
-- guessable and consecutive, and anyone who can see one student's ID could
-- confirm attendance for their neighbours.
create or replace function public.generate_student_id()
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  candidate text;
  attempts  int := 0;
begin
  loop
    -- 1000000000..9999999999 — always 10 digits, never a leading zero.
    candidate := (1000000000 + floor(random() * 9000000000))::bigint::text;
    exit when not exists (
      select 1 from public.profiles where student_id = candidate
    );
    attempts := attempts + 1;
    if attempts > 50 then
      raise exception 'could not allocate a unique student_id after % attempts', attempts;
    end if;
  end loop;
  return candidate;
end;
$$;

-- Backfill everyone who predates this column.
update public.profiles
set student_id = public.generate_student_id()
where student_id is null;

-- Now that no nulls remain, enforce the invariants.
create unique index if not exists profiles_student_id_key
  on public.profiles (student_id);

alter table public.profiles
  alter column student_id set default public.generate_student_id();

alter table public.profiles
  alter column student_id set not null;

-- "Never changes": block any update that would alter an assigned ID, for
-- everyone including admins. A student's ID is their identity at events; a
-- changed ID would silently invalidate whatever a host wrote down.
create or replace function public.freeze_student_id()
returns trigger
language plpgsql
as $$
begin
  if old.student_id is not null and new.student_id is distinct from old.student_id then
    raise exception 'student_id is immutable';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_freeze_student_id on public.profiles;
create trigger trg_freeze_student_id
  before update on public.profiles
  for each row
  execute function public.freeze_student_id();

-- 2. Manual attendance confirmation -----------------------------------------
-- SECURITY DEFINER: the host confirming attendance has no RLS right to write
-- another user's attendance row or point transaction, and shouldn't.
--
-- Mirrors `scan_event_attendance`'s result shape so the Dart side can reuse
-- `EventScanResult`/`EventScanStatus` verbatim:
--   {status, points, event_title}
create or replace function public.confirm_attendance_by_student_id(
  _event_id   uuid,
  _student_id text,
  _session_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id  uuid;
  v_event    public.events%rowtype;
  v_points   int;
  v_title    text;
begin
  select * into v_event from public.events where id = _event_id;
  if not found then
    return jsonb_build_object('status', 'invalid', 'points', 0);
  end if;
  v_title := v_event.title;

  -- Only an admin or the event's own host may confirm.
  if not public.is_admin() and v_event.created_by <> auth.uid() then
    return jsonb_build_object('status', 'invalid', 'points', 0, 'event_title', v_title);
  end if;

  select id into v_user_id
  from public.profiles
  where student_id = regexp_replace(coalesce(_student_id, ''), '\s', '', 'g');

  if v_user_id is null then
    return jsonb_build_object('status', 'invalid', 'points', 0, 'event_title', v_title);
  end if;

  -- Registration is required, exactly as for a scan.
  if not exists (
    select 1 from public.event_registrations
    where event_id = _event_id and user_id = v_user_id
  ) then
    return jsonb_build_object('status', 'not_registered', 'points', 0, 'event_title', v_title);
  end if;

  -- Scan-once, per session when this is a program.
  if exists (
    select 1 from public.event_attendance
    where event_id = _event_id
      and user_id  = v_user_id
      and (_session_id is null or session_id = _session_id)
  ) then
    return jsonb_build_object('status', 'already_scanned', 'points', 0, 'event_title', v_title);
  end if;

  v_points := coalesce(v_event.points, 0);

  insert into public.event_attendance (event_id, user_id, session_id)
  values (_event_id, v_user_id, _session_id);

  -- Points are awarded through point_transactions, the same table the scan
  -- path writes to — so balances, history and the points_earned notification
  -- all behave identically to a scanned check-in.
  if v_points > 0 then
    insert into public.point_transactions (user_id, amount, reason, metadata)
    values (
      v_user_id,
      v_points,
      'event_attendance',
      jsonb_build_object(
        'event_id',     _event_id,
        'session_id',   _session_id,
        'event_title',  v_title,
        'confirmed_by', auth.uid(),
        'method',       'student_id'
      )
    );
  end if;

  -- 'ok' (not 'confirmed') to match `scan_event_attendance`'s contract,
  -- which EventsRepositoryImpl already maps.
  return jsonb_build_object('status', 'ok', 'points', v_points, 'event_title', v_title);
end;
$$;

grant execute on function public.confirm_attendance_by_student_id(uuid, text, uuid)
  to authenticated;

-- 3. Let hosts/admins resolve an ID to a name before confirming --------------
-- So the UI can show "Confirm attendance for <name>?" instead of making
-- someone commit to a bare 10-digit string they may have mistyped.
create or replace function public.lookup_student_by_id(_student_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id   uuid;
  v_name text;
begin
  if not public.is_admin()
     and not exists (select 1 from public.events where created_by = auth.uid())
  then
    return null;
  end if;

  select id, full_name into v_id, v_name
  from public.profiles
  where student_id = regexp_replace(coalesce(_student_id, ''), '\s', '', 'g');

  if v_id is null then
    return null;
  end if;
  return jsonb_build_object('user_id', v_id, 'full_name', v_name);
end;
$$;

grant execute on function public.lookup_student_by_id(text) to authenticated;
