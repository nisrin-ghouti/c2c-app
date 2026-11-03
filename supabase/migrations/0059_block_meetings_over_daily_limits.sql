-- Enforce the two daily meeting limits by BLOCKING the meeting, not just
-- zeroing its points.
--
--   * a student may meet the same student at most once per day
--   * a student may meet at most 5 different students per day
--
-- Until now both rules lived only in `scan_meeting_qr`, which let the meeting
-- complete and awarded 0 points. Students could still fill a day with
-- meetings and simply earn nothing, which is not what the spec asks for.
--
-- Only *accepted* proposals consume a slot (a pending invitation does not), so
-- the limits are evaluated against `meeting_proposals.status = 'accepted'` for
-- the proposal's scheduled DATE — not "today", since proposals are for future
-- times. Both participants are checked: if either is at their limit for that
-- date, the meeting is refused.
--
-- `scan_meeting_qr`'s existing zero-points behaviour is deliberately left in
-- place as a backstop. It still covers meetings accepted before this
-- migration, the separate group-meeting path (`award_meeting_points`), and any
-- direct RPC call that bypasses these checks.

-- --------------------------------------------------------------- helpers
-- Shared by propose_meeting and respond_to_meeting_proposal so the two paths
-- can never drift apart.

-- Does _a already have an accepted meeting with _b on _day?
create or replace function public.has_accepted_meeting_with(
  _a uuid,
  _b uuid,
  _day date,
  _exclude_proposal uuid default null
)
returns boolean
language sql
security definer
set search_path to 'public'
as $$
  select exists (
    select 1
    from public.meeting_proposals p
    where p.status = 'accepted'
      and p.scheduled_at::date = _day
      and (_exclude_proposal is null or p.id <> _exclude_proposal)
      and _a in (select m from public.chat_member_ids(p.chat_id) m)
      and _b in (select m from public.chat_member_ids(p.chat_id) m)
  );
$$;

-- How many DISTINCT partners does _user have accepted meetings with on _day?
create or replace function public.accepted_meeting_partners_on(
  _user uuid,
  _day date,
  _exclude_proposal uuid default null
)
returns integer
language sql
security definer
set search_path to 'public'
as $$
  select count(distinct other.m)::int
  from public.meeting_proposals p
  cross join lateral (
    select m from public.chat_member_ids(p.chat_id) m where m <> _user
  ) other
  where p.status = 'accepted'
    and p.scheduled_at::date = _day
    and (_exclude_proposal is null or p.id <> _exclude_proposal)
    and _user in (select m from public.chat_member_ids(p.chat_id) m);
$$;

revoke all on function public.has_accepted_meeting_with(uuid, uuid, date, uuid) from public;
revoke all on function public.accepted_meeting_partners_on(uuid, date, uuid) from public;
grant execute on function public.has_accepted_meeting_with(uuid, uuid, date, uuid) to authenticated;
grant execute on function public.accepted_meeting_partners_on(uuid, date, uuid) to authenticated;

-- --------------------------------------------------------- propose_meeting
-- Fail fast: refuse to create a proposal that could never be honoured. This is
-- a UX guard, not the real enforcement — nothing is accepted at propose time,
-- so `respond_to_meeting_proposal` must carry the same checks (see note at the
-- foot of this file).
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
  _me uuid := auth.uid();
  _other uuid;
  _day date := _scheduled_at::date;
begin
  select * into _chat from chats where id = _chat_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;
  if _chat.user_a <> _me and _chat.user_b <> _me then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if _ends_at_resolved <= _scheduled_at then
    return jsonb_build_object('status', 'invalid_window');
  end if;

  _other := case when _chat.user_a = _me then _chat.user_b else _chat.user_a end;

  -- One meeting per pair per day.
  if public.has_accepted_meeting_with(_me, _other, _day) then
    return jsonb_build_object('status', 'daily_pair_limit');
  end if;

  -- Five distinct partners per day, for either participant.
  if public.accepted_meeting_partners_on(_me, _day) >= 5 then
    return jsonb_build_object('status', 'daily_partner_limit', 'who', 'self');
  end if;
  if public.accepted_meeting_partners_on(_other, _day) >= 5 then
    return jsonb_build_object('status', 'daily_partner_limit', 'who', 'other');
  end if;

  insert into meeting_proposals (chat_id, proposed_by, scheduled_at, ends_at, location, notes)
  values (_chat_id, _me, _scheduled_at, _ends_at_resolved, _location, _notes)
  returning id into _proposal_id;

  insert into chat_messages (chat_id, sender_id, body, message_type, metadata)
  values (_chat_id, _me, 'Meeting proposal', 'meeting_proposal', jsonb_build_object('proposal_id', _proposal_id));

  return jsonb_build_object('status', 'ok', 'id', _proposal_id);
end;
$$;

grant execute on function public.propose_meeting(uuid, timestamptz, text, text, timestamptz) to authenticated;

-- ------------------------------------------- respond_to_meeting_proposal
-- The real enforcement point. Nothing is accepted at propose time, so several
-- students can each propose for the same day (every one allowed) and the
-- recipient could otherwise accept them all.
--
-- Body preserved verbatim from the deployed function, with the limit checks
-- added before the status update. Only acceptance is gated — declining a
-- proposal must always work, whatever the responder's schedule looks like.
create or replace function public.respond_to_meeting_proposal(
  _proposal_id uuid,
  _accept      boolean
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _proposal meeting_proposals%rowtype;
  _chat chats%rowtype;
  _me uuid := auth.uid();
  _other uuid;
  _day date;
begin
  select * into _proposal from meeting_proposals where id = _proposal_id;
  if not found then
    return jsonb_build_object('status', 'not_found');
  end if;

  select * into _chat from chats where id = _proposal.chat_id;
  if _chat.user_a <> _me and _chat.user_b <> _me then
    return jsonb_build_object('status', 'forbidden');
  end if;
  if _proposal.proposed_by = _me then
    return jsonb_build_object('status', 'forbidden');
  end if;
  if _proposal.status <> 'pending' then
    return jsonb_build_object('status', 'already_responded');
  end if;

  if _accept then
    -- The responder is never the proposer (checked above), so the other
    -- participant is the proposer.
    _other := _proposal.proposed_by;
    _day := _proposal.scheduled_at::date;

    -- One meeting per pair per day.
    if public.has_accepted_meeting_with(_me, _other, _day, _proposal_id) then
      return jsonb_build_object('status', 'daily_pair_limit');
    end if;

    -- Five distinct partners per day, for either participant.
    if public.accepted_meeting_partners_on(_me, _day, _proposal_id) >= 5 then
      return jsonb_build_object('status', 'daily_partner_limit', 'who', 'self');
    end if;
    if public.accepted_meeting_partners_on(_other, _day, _proposal_id) >= 5 then
      return jsonb_build_object('status', 'daily_partner_limit', 'who', 'other');
    end if;
  end if;

  update meeting_proposals set status = case when _accept then 'accepted' else 'declined' end
  where id = _proposal_id;

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.respond_to_meeting_proposal(uuid, boolean) to authenticated;

-- ------------------------------------------------------------ after running
-- `create or replace` only replaces a function with a MATCHING signature. If
-- the deployed one differed, this creates a second overload and PostgREST
-- starts failing with an ambiguity error. Confirm exactly one remains:
--
--   select proname, pg_get_function_identity_arguments(oid), prosecdef
--   from pg_proc
--   where proname in ('respond_to_meeting_proposal', 'propose_meeting');
--
-- Two rows for a name means an accidental overload — drop the stale one.
