-- Scheduled one-on-one meetings: the two-sided QR handshake.
--
-- Self-contained (per the chosen approach) — it does NOT touch the existing
-- `claim_meeting_session` "Connect via QR" flow, which stays for spontaneous
-- meetups. This covers meetings scheduled in chat: once accepted, each student
-- opens a Meeting Screen showing a QR that rotates every 10s, and each must
-- scan the other's QR. Points are awarded only after BOTH directions succeed.
--
-- Identity is carried by the token, not by chat membership: a scan records the
-- token owner as "scanned" and the caller as "scanner". Points require both
-- directions, so both real students must physically show + scan a live (15s)
-- code — a third party can't complete anything.

-- 1. Rotating QR tokens ------------------------------------------------------
create table if not exists public.meeting_scan_tokens (
  token       text primary key,
  proposal_id uuid not null references public.meeting_proposals (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  expires_at  timestamptz not null,
  created_at  timestamptz not null default now()
);

create index if not exists meeting_scan_tokens_proposal_idx
  on public.meeting_scan_tokens (proposal_id);

-- 2. Directional check-ins (who scanned whom, per meeting) -------------------
create table if not exists public.meeting_checkins (
  proposal_id uuid not null references public.meeting_proposals (id) on delete cascade,
  scanner_id  uuid not null references public.profiles (id) on delete cascade,
  scanned_id  uuid not null references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (proposal_id, scanner_id)
);

-- 3. Completion + points bookkeeping (one row per finished meeting) ----------
-- Its existence is what makes the point award idempotent: the first scan that
-- observes both directions inserts here; a duplicate does nothing.
create table if not exists public.meeting_completions (
  proposal_id  uuid primary key references public.meeting_proposals (id) on delete cascade,
  completed_at timestamptz not null default now(),
  points_each  int not null default 0
);

alter table public.meeting_scan_tokens enable row level security;
alter table public.meeting_checkins    enable row level security;
alter table public.meeting_completions enable row level security;

-- Participants read their own meeting's rows (for the live realtime state);
-- all writes go exclusively through the SECURITY DEFINER RPCs below.
drop policy if exists meeting_checkins_read on public.meeting_checkins;
create policy meeting_checkins_read
  on public.meeting_checkins for select
  to authenticated
  using (scanner_id = auth.uid() or scanned_id = auth.uid());

drop policy if exists meeting_completions_read on public.meeting_completions;
create policy meeting_completions_read
  on public.meeting_completions for select
  to authenticated
  using (
    exists (
      select 1 from public.meeting_checkins c
      where c.proposal_id = meeting_completions.proposal_id
        and (c.scanner_id = auth.uid() or c.scanned_id = auth.uid())
    )
  );

-- Realtime so each screen's two sections update the instant the other scans.
do $$
begin
  begin
    alter publication supabase_realtime add table public.meeting_checkins;
  exception when duplicate_object then null;
  end;
end $$;
alter table public.meeting_checkins replica identity full;

-- 4. Chat-member resolver (the one place that needs chat membership) ---------
-- Used only by `list_my_meetings` to find meetings where the caller is the
-- accepter (not the proposer). The mutual-scan path does NOT use this.
--
-- The base chat schema isn't in this repo, so this auto-detects the two most
-- common shapes. If neither matches, it raises a clear error naming what to
-- fix — a one-line change once the real shape is known.
create or replace function public.chat_member_ids(_chat_id uuid)
returns setof uuid
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  -- Shape A: a join table chat_participants(chat_id, user_id).
  if to_regclass('public.chat_participants') is not null then
    return query
      select user_id from public.chat_participants where chat_id = _chat_id;
    return;
  end if;

  -- Shape B: chats(user_a_id, user_b_id) or (user_a, user_b).
  if to_regclass('public.chats') is not null then
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'chats' and column_name = 'user_a_id'
    ) then
      return query
        select c.user_a_id from public.chats c where c.id = _chat_id
        union
        select c.user_b_id from public.chats c where c.id = _chat_id;
      return;
    elsif exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'chats' and column_name = 'user_a'
    ) then
      return query
        select c.user_a from public.chats c where c.id = _chat_id
        union
        select c.user_b from public.chats c where c.id = _chat_id;
      return;
    end if;
  end if;

  raise exception
    'chat_member_ids: could not find chat membership table — adjust this function to your schema';
end;
$$;

-- 5. Rotate my QR token ------------------------------------------------------
-- Returns {token, expires_at}. 15s TTL; the client refreshes every 10s so a
-- scan always meets a live code (the 5s overlap covers clock skew / latency).
create or replace function public.rotate_meeting_token(_proposal_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_token   text;
  v_expires timestamptz;
begin
  if not exists (
    select 1 from public.meeting_proposals
    where id = _proposal_id and status = 'accepted'
  ) then
    raise exception 'meeting is not accepted' using errcode = '42501';
  end if;

  v_token := encode(gen_random_bytes(18), 'hex');
  v_expires := now() + interval '15 seconds';

  insert into public.meeting_scan_tokens (token, proposal_id, user_id, expires_at)
  values (v_token, _proposal_id, auth.uid(), v_expires);

  -- Opportunistic cleanup of this user's stale tokens for this meeting.
  delete from public.meeting_scan_tokens
  where proposal_id = _proposal_id and user_id = auth.uid() and expires_at < now();

  return jsonb_build_object('token', v_token, 'expires_at', v_expires);
end;
$$;

grant execute on function public.rotate_meeting_token(uuid) to authenticated;

-- 6. Scan the other student's QR --------------------------------------------
-- Records the directional check-in and, if both directions now exist, awards
-- points to both students. Returns:
--   {status, i_scanned_them, they_scanned_me, completed, points, other_user_id}
-- status: 'ok' | 'own_code' | 'expired' | 'invalid'
create or replace function public.scan_meeting_qr(_raw text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token     text := replace(coalesce(_raw, ''), 'c2c:meeting:', '');
  v_owner     uuid;
  v_proposal  uuid;
  v_expires   timestamptz;
  v_me        uuid := auth.uid();
  v_reverse   boolean;
  v_points    int := 0;
  v_prior     int;
  v_reason    text;
  v_today_pair boolean;
begin
  select user_id, proposal_id, expires_at
    into v_owner, v_proposal, v_expires
  from public.meeting_scan_tokens
  where token = v_token;

  if v_owner is null then
    return jsonb_build_object('status', 'invalid');
  end if;
  if v_owner = v_me then
    return jsonb_build_object('status', 'own_code');
  end if;
  if now() > v_expires then
    return jsonb_build_object('status', 'expired', 'other_user_id', v_owner);
  end if;

  -- Record my scan of them (idempotent on the pair key).
  insert into public.meeting_checkins (proposal_id, scanner_id, scanned_id)
  values (v_proposal, v_me, v_owner)
  on conflict (proposal_id, scanner_id) do nothing;

  -- Did they already scan me?
  select exists (
    select 1 from public.meeting_checkins
    where proposal_id = v_proposal and scanner_id = v_owner and scanned_id = v_me
  ) into v_reverse;

  if v_reverse and not exists (
    select 1 from public.meeting_completions where proposal_id = v_proposal
  ) then
    -- Both directions done → award points, unless this exact pair already
    -- earned a scheduled-meeting point today.
    select exists (
      select 1
      from public.meeting_completions mc
      join public.meeting_checkins ck on ck.proposal_id = mc.proposal_id
      where mc.completed_at::date = now()::date
        and ((ck.scanner_id = v_me and ck.scanned_id = v_owner)
          or (ck.scanner_id = v_owner and ck.scanned_id = v_me))
    ) into v_today_pair;

    if not v_today_pair then
      -- Points by prior *completed* meetings between this unordered pair.
      select count(*) into v_prior
      from public.meeting_completions mc
      join public.meeting_checkins ck on ck.proposal_id = mc.proposal_id
      where (ck.scanner_id = v_me and ck.scanned_id = v_owner);

      if v_prior = 0 then
        v_points := 25; v_reason := 'meeting_first';
      elsif v_prior = 1 then
        v_points := 20; v_reason := 'meeting_second';
      else
        v_points := 10; v_reason := 'meeting_repeat';
      end if;

      insert into public.point_transactions (user_id, amount, reason, metadata)
      select uid, v_points, v_reason,
             jsonb_build_object('proposal_id', v_proposal, 'other_user_id',
               case when uid = v_me then v_owner else v_me end)
      from (values (v_me), (v_owner)) as t(uid);
    end if;

    insert into public.meeting_completions (proposal_id, points_each)
    values (v_proposal, v_points)
    on conflict (proposal_id) do nothing;
  end if;

  return jsonb_build_object(
    'status', 'ok',
    'other_user_id', v_owner,
    'i_scanned_them', true,
    'they_scanned_me', v_reverse,
    'completed', v_reverse,
    'points', v_points
  );
end;
$$;

grant execute on function public.scan_meeting_qr(text) to authenticated;

-- 7. Current progress for one meeting (initial paint before realtime) --------
create or replace function public.get_meeting_progress(_proposal_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
begin
  return jsonb_build_object(
    'i_scanned_them', exists (
      select 1 from public.meeting_checkins
      where proposal_id = _proposal_id and scanner_id = v_me
    ),
    'they_scanned_me', exists (
      select 1 from public.meeting_checkins
      where proposal_id = _proposal_id and scanned_id = v_me
    ),
    'completed', exists (
      select 1 from public.meeting_completions where proposal_id = _proposal_id
    )
  );
end;
$$;

grant execute on function public.get_meeting_progress(uuid) to authenticated;

-- 8. My accepted meetings, for "My Events" -----------------------------------
-- Returns accepted proposals where the caller is a participant (proposer or
-- the other chat member), with the other student's name and completion state.
create or replace function public.list_my_meetings()
returns table (
  proposal_id  uuid,
  scheduled_at timestamptz,
  location     text,
  notes        text,
  other_user_id uuid,
  other_name    text,
  completed     boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.scheduled_at,
    p.location,
    p.notes,
    other.id,
    other.full_name,
    exists (select 1 from public.meeting_completions mc where mc.proposal_id = p.id)
  from public.meeting_proposals p
  join lateral (
    select m as id from public.chat_member_ids(p.chat_id) m
    where m <> auth.uid()
    limit 1
  ) om on true
  join public.profiles other on other.id = om.id
  where p.status = 'accepted'
    and auth.uid() in (select m from public.chat_member_ids(p.chat_id) m)
  order by p.scheduled_at desc;
$$;

grant execute on function public.list_my_meetings() to authenticated;
