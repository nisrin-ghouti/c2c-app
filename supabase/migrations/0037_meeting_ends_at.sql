-- The student-to-student QR meeting screen currently has no end boundary —
-- the "open meeting" button/route is available forever once a proposal is
-- accepted. Add an end time alongside the existing scheduled (start) time so
-- the meeting window can be enforced both client-side (hide the button
-- outside the window) and server-side (refuse to issue scan tokens outside
-- it).

alter table public.meeting_proposals add column if not exists ends_at timestamptz;

-- Backfill existing rows with a 1-hour default window so the new NOT NULL
-- constraint below doesn't fail on data that predates this column.
update public.meeting_proposals
set ends_at = scheduled_at + interval '1 hour'
where ends_at is null;

alter table public.meeting_proposals alter column ends_at set not null;

alter table public.meeting_proposals drop constraint if exists meeting_proposals_ends_after_start;
alter table public.meeting_proposals add constraint meeting_proposals_ends_after_start
  check (ends_at > scheduled_at);

-- `_ends_at` is trailing + defaulted so any not-yet-updated client still
-- gets a valid (1-hour) window instead of failing outright. Adding a
-- parameter makes this a new overload rather than a true replace — drop the
-- old 4-arg signature first so only one `propose_meeting` remains.
drop function if exists public.propose_meeting(uuid, timestamptz, text, text);

create or replace function public.propose_meeting(
  _chat_id      uuid,
  _scheduled_at timestamptz,
  _location     text,
  _notes        text,
  _ends_at      timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _chat chats%rowtype;
  _proposal_id uuid;
  _ends_at_resolved timestamptz := coalesce(_ends_at, _scheduled_at + interval '1 hour');
begin
  select * into _chat from chats where id = _chat_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;
  if _chat.user_a <> auth.uid() and _chat.user_b <> auth.uid() then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if _ends_at_resolved <= _scheduled_at then
    return jsonb_build_object('status', 'invalid_window');
  end if;

  insert into meeting_proposals (chat_id, proposed_by, scheduled_at, ends_at, location, notes)
  values (_chat_id, auth.uid(), _scheduled_at, _ends_at_resolved, _location, _notes)
  returning id into _proposal_id;

  insert into chat_messages (chat_id, sender_id, body, message_type, metadata)
  values (_chat_id, auth.uid(), 'Meeting proposal', 'meeting_proposal', jsonb_build_object('proposal_id', _proposal_id));

  return jsonb_build_object('status', 'ok', 'id', _proposal_id);
end;
$$;

grant execute on function public.propose_meeting(uuid, timestamptz, text, text, timestamptz) to authenticated;

-- Return shape changed (added ends_at) — Postgres requires dropping a
-- function before CREATE OR REPLACE can change its OUT-parameter row type.
drop function if exists public.list_my_meetings();

create function public.list_my_meetings()
returns table (
  proposal_id  uuid,
  scheduled_at timestamptz,
  ends_at      timestamptz,
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
    p.ends_at,
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

-- Server-side backstop: refuse to issue a scan token outside the meeting's
-- own [scheduled_at, ends_at] window, mirroring the client hiding the
-- button for the same window.
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
    where id = _proposal_id
      and status = 'accepted'
      and now() between scheduled_at and ends_at
  ) then
    raise exception 'meeting is not currently active' using errcode = '42501';
  end if;

  v_token := encode(gen_random_bytes(18), 'hex');
  v_expires := now() + interval '15 seconds';

  insert into public.meeting_scan_tokens (token, proposal_id, user_id, expires_at)
  values (v_token, _proposal_id, auth.uid(), v_expires);

  delete from public.meeting_scan_tokens
  where proposal_id = _proposal_id and user_id = auth.uid() and expires_at < now();

  return jsonb_build_object('token', v_token, 'expires_at', v_expires);
end;
$$;

grant execute on function public.rotate_meeting_token(uuid) to authenticated;
