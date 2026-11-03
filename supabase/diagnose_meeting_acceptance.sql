-- Why doesn't accepting a meeting in the chat work / stick?
--
-- `meeting_proposals` is the one table in this feature that is NOT created by
-- any migration in this repo — it comes from the base schema, so its RLS
-- policies and any triggers on it exist only in the live database and can't be
-- read from the code. Migration 0073 fixes everything that IS visible here
-- (realtime publication, a member-SELECT policy, an idempotent
-- `respond_to_meeting_proposal`), and the app now surfaces every refusal
-- instead of failing silently. If accepting still misbehaves after that, the
-- cause is in this table's live definition. This locates it.
--
-- Read-only. Run the whole file and read each result in turn.

-- 1. What does the status column actually allow?
--    `respond_to_meeting_proposal` writes 'accepted'/'declined'. If a CHECK or
--    enum here doesn't permit one of those, the UPDATE raises, the RPC aborts,
--    and the client sees a thrown request rather than a status — which before
--    0073 looked exactly like "the button does nothing".
select a.attname        as column_name,
       format_type(a.atttypid, a.atttypmod) as column_type,
       (select string_agg(pg_get_constraintdef(c.oid), ' | ')
        from pg_constraint c
        where c.conrelid = 'public.meeting_proposals'::regclass
          and c.contype = 'c') as check_constraints,
       (select string_agg(e.enumlabel, ', ' order by e.enumsortorder)
        from pg_enum e
        where e.enumtypid = a.atttypid) as enum_labels
from pg_attribute a
where a.attrelid = 'public.meeting_proposals'::regclass
  and a.attname = 'status'
  and a.attnum > 0;

-- 2. Is there a trigger on the table that could abort the UPDATE?
--    A notification trigger writing a `type` the notifications CHECK doesn't
--    allow is the classic version of this: the insert fails, the exception
--    propagates out of the RPC, and the acceptance is rolled back.
select tgname    as trigger_name,
       tgenabled as enabled,          -- 'O' = enabled, 'D' = disabled
       pg_get_triggerdef(oid) as definition
from pg_trigger
where tgrelid = 'public.meeting_proposals'::regclass
  and not tgisinternal
order by tgname;

-- 3. Can both chat members READ the row?
--    This is what decides whether realtime delivers the status change to the
--    PROPOSER (item 12). Realtime honours RLS: a member who can't SELECT the
--    row receives no change events for it, so their card never leaves
--    "waiting for a response". Expect `meeting_proposals_select_members`
--    (installed by 0073) among these, and note whether RLS is on at all.
select c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as rls_forced
from pg_class c
where c.oid = 'public.meeting_proposals'::regclass;

select policyname,
       permissive,      -- PERMISSIVE policies OR together; RESTRICTIVE ANDs
       cmd,
       roles::text,
       qual             as using_expression
from pg_policies
where schemaname = 'public'
  and tablename = 'meeting_proposals'
order by permissive desc, policyname;

-- 4. Is the table published for realtime?
--    Expect one row. Empty means the app subscribes, reports healthy, and
--    never fires — the silent failure 0005/0063/0067 all document. Migration
--    0073 adds it.
select schemaname, tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
  and schemaname = 'public'
  and tablename = 'meeting_proposals';

-- 5. Which version of the RPC is installed?
--    Expect exactly ONE `respond_to_meeting_proposal`. Two overloads (e.g. a
--    base-schema one with differently-named parameters alongside 0073's) means
--    PostgREST may be resolving the call to the wrong one.
select p.oid::regprocedure as signature,
       pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer,
       -- 0073's body is the one that returns 'proposal_status'.
       (pg_get_functiondef(p.oid) ilike '%proposal_status%') as is_0073_or_later
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'respond_to_meeting_proposal';

-- 6. Do the helper functions the accept path calls exist?
--    A missing one raises inside the RPC rather than returning a status.
select to_regprocedure('public.campus_date(timestamptz)') is not null as campus_date,
       to_regprocedure('public.has_accepted_meeting_with(uuid,uuid,date,uuid)') is not null as pair_limit_fn,
       to_regprocedure('public.accepted_meeting_partners_on(uuid,date,uuid)') is not null as partner_limit_fn,
       to_regprocedure('public.chat_member_ids(uuid)') is not null as chat_member_ids;

-- 7. What do the recent proposals actually look like?
--    If `status` is moving to 'accepted' here but the proposer's chat still
--    says "waiting", the write is fine and the problem is delivery (3 and 4).
--    If it stays 'pending', the write is being refused or rolled back (1, 2).
select id,
       chat_id,
       proposed_by,
       status,
       scheduled_at,
       public.campus_date(scheduled_at) as campus_day
from public.meeting_proposals
order by proposed_at desc
limit 20;

-- 8. Is a daily limit the real answer?
--    `respond_to_meeting_proposal` refuses an acceptance that would break
--    either cap — a legitimate refusal, which the app now reports as a
--    snackbar instead of silently. Counts per student per campus day:
select public.campus_date(p.scheduled_at) as campus_day,
       m                                   as student,
       count(distinct other.m)             as accepted_partners_that_day
from public.meeting_proposals p
cross join lateral (select m from public.chat_member_ids(p.chat_id) m) m_outer(m)
cross join lateral (
  select m from public.chat_member_ids(p.chat_id) m where m <> m_outer.m
) other
where p.status = 'accepted'
group by 1, 2
having count(distinct other.m) >= 4   -- the cap is 5
order by 1 desc, 3 desc
limit 50;
