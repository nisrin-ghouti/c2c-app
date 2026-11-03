-- Fix: Student B accepts a meeting in the chat and Student A keeps seeing
-- "waiting for a response"; and accepting twice reads as the button failing.
--
-- Two separate problems, one code path.
--
-- 1. NOTHING TOLD STUDENT A. `MeetingProposalCard` read the proposal once
--    (`getProposal`) and the responder's own `ref.invalidate` was the only
--    thing that ever refetched it. The proposer's app has no way to know when
--    the other side writes the row, so their card kept rendering `pending`
--    until the thread was closed and reopened. The app now subscribes to the
--    row (`meetingProposalProvider` is a realtime stream), which needs
--    `meeting_proposals` in the `supabase_realtime` publication and SELECT-able
--    by BOTH chat members. Either one missing is the same silent failure 0005,
--    0063 and 0067 all document: the subscription connects, reports healthy,
--    and never fires.
--
-- 2. A SECOND TAP LOOKED LIKE A FAILURE. `respond_to_meeting_proposal` refuses
--    anything that isn't `pending` with `already_responded`, so a double tap —
--    or a retry after a dropped connection that actually succeeded — came back
--    as a refusal on a meeting that had in fact just been accepted. It is now
--    idempotent: re-sending the SAME answer by the SAME responder returns `ok`
--    with the current row. Answering the OTHER way still refuses, because
--    that's a real conflict, not a duplicate.
--
-- `meeting_proposals` predates this migration series (it is created by the base
-- schema, not by any file here — see 0037, which only adds `ends_at`), so every
-- step below is guarded and nothing existing is dropped. In particular the RLS
-- section adds a PERMISSIVE policy, which ORs with whatever policy is already
-- on the table, and it only runs where RLS is already enabled: switching RLS on
-- for a table that has none would turn a working read into a blocked one.
--
-- Idempotent: re-running is a no-op.

-- 1. Realtime ---------------------------------------------------------------
do $$
begin
  if to_regclass('public.meeting_proposals') is null then
    raise notice 'skipping: public.meeting_proposals not found';
    return;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'meeting_proposals'
  ) then
    alter publication supabase_realtime add table public.meeting_proposals;
    raise notice 'realtime: added public.meeting_proposals to supabase_realtime';
  else
    raise notice 'realtime: public.meeting_proposals was already published';
  end if;
end $$;

-- 2. Both chat members may read the proposal --------------------------------
-- Realtime honours RLS, so a member who can't SELECT the row receives no
-- change events for it — which is exactly the half of problem 1 that a
-- publication alone doesn't fix. `chat_member_ids` is the same helper
-- `propose_meeting`/`notify_new_chat_message` use to resolve a chat's two
-- participants.
do $$
begin
  if to_regclass('public.meeting_proposals') is null then
    return;
  end if;

  if not (
    select c.relrowsecurity
    from pg_class c
    where c.oid = 'public.meeting_proposals'::regclass
  ) then
    raise notice
      'meeting_proposals has RLS disabled; leaving it alone (reads already work)';
    return;
  end if;

  execute 'drop policy if exists meeting_proposals_select_members on public.meeting_proposals';
  execute $pol$
    create policy meeting_proposals_select_members
      on public.meeting_proposals for select
      to authenticated
      using (
        auth.uid() in (select m from public.chat_member_ids(chat_id) m)
      )
  $pol$;
  raise notice 'rls: meeting_proposals_select_members installed';
end $$;

-- 3. An idempotent response -------------------------------------------------
-- Body preserved from 0060 (which is itself 0059 retimed onto campus_date):
-- the same membership, authorship, daily-pair and daily-partner gates in the
-- same order. What changes:
--
--   * a repeat of the same answer by the same responder returns `ok` instead
--     of `already_responded`, so a double tap or a retried request is a no-op
--     rather than an error;
--   * the answer carries the resulting `status`, so the client never has to
--     follow up with a read to find out what happened.
--
-- `responded_by` is NOT recorded — there is only ever one person who may
-- answer (the member who didn't propose), so "same responder" is already
-- implied by passing the authorship gate below.
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
  _target text := case when _accept then 'accepted' else 'declined' end;
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

  -- New in 0073: the duplicate case. Already in the state being asked for, by
  -- the only person who could have put it there, so there is nothing to do and
  -- nothing went wrong.
  if _proposal.status = _target then
    return jsonb_build_object(
      'status', 'ok',
      'proposal_status', _proposal.status,
      'unchanged', true
    );
  end if;

  -- Still a conflict: answered already, and the opposite way.
  if _proposal.status <> 'pending' then
    return jsonb_build_object(
      'status', 'already_responded',
      'proposal_status', _proposal.status
    );
  end if;

  if _accept then
    _other := _proposal.proposed_by;
    _day := public.campus_date(_proposal.scheduled_at);

    if public.has_accepted_meeting_with(_me, _other, _day, _proposal_id) then
      return jsonb_build_object('status', 'daily_pair_limit');
    end if;
    if public.accepted_meeting_partners_on(_me, _day, _proposal_id) >= 5 then
      return jsonb_build_object('status', 'daily_partner_limit', 'who', 'self');
    end if;
    if public.accepted_meeting_partners_on(_other, _day, _proposal_id) >= 5 then
      return jsonb_build_object('status', 'daily_partner_limit', 'who', 'other');
    end if;
  end if;

  -- `and status = 'pending'` makes the write itself the arbiter: two requests
  -- racing can't both apply, the loser simply updates no row and is reported
  -- as the duplicate it is.
  update meeting_proposals
    set status = _target
  where id = _proposal_id
    and status = 'pending';

  if not found then
    select * into _proposal from meeting_proposals where id = _proposal_id;
    if _proposal.status = _target then
      return jsonb_build_object(
        'status', 'ok',
        'proposal_status', _proposal.status,
        'unchanged', true
      );
    end if;
    return jsonb_build_object(
      'status', 'already_responded',
      'proposal_status', _proposal.status
    );
  end if;

  return jsonb_build_object('status', 'ok', 'proposal_status', _target);
end;
$$;

grant execute on function public.respond_to_meeting_proposal(uuid, boolean) to authenticated;

-- Confirm what's in place now:
--
--   select schemaname, tablename from pg_publication_tables
--   where pubname = 'supabase_realtime' and tablename = 'meeting_proposals';
--
--   select policyname, permissive, cmd, qual
--   from pg_policies where tablename = 'meeting_proposals';
