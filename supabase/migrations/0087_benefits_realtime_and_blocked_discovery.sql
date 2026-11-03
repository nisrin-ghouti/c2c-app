-- Three things the app needs to reflect reality without a restart, plus the
-- one place a blocked student was still visible.
--
-- 1. BENEFITS DON'T UPDATE UNTIL THE APP IS KILLED.
--    Same shape as the events bug 0063 fixed. `benefitsCatalogProvider` is
--    autoDispose, but the Benefits tab is a bottom-nav branch that
--    `StatefulShellRoute.indexedStack` keeps mounted for the whole session, so
--    nothing ever disposed it and the session's first fetch was its only
--    fetch. The app now subscribes to `benefits` and drops the cache when a
--    row moves (`benefitsLiveRefreshProvider`) — which receives nothing unless
--    the table is in the `supabase_realtime` publication.
--
-- 2. BEING ACCEPTED ONTO A PROGRAM HAS TO REACH THE OPEN SCREEN.
--    A student who registers for a program is a registrant; an admin then
--    takes them on by inserting into `program_accepted_participants` (0071).
--    That write touches no `events` row, so the events subscription never
--    fires for it and the student's "waiting for approval" status would sit
--    there until a restart. Publishing the table lets the acceptance itself
--    be the trigger. RLS still applies — `program_accepted_select_self`
--    restricts a student to their own row — so this reveals nothing about who
--    else was accepted.
--
-- 3. BLOCKED STUDENTS WERE STILL DISCOVERABLE.
--    `list_match_candidates` filters `deleted_at is null` and
--    `is_student_eligible`, but never `banned_at`. An admin blocking a student
--    therefore stopped them signing in (`currentUserBanProvider` signs them
--    out) without removing them from everyone else's matching list, where they
--    could still be opened and messaged.
--
--    CHAT HISTORY IS DELIBERATELY UNTOUCHED. This changes discovery only —
--    `list_my_chats`, `chat_messages` and every existing thread behave exactly
--    as before, so a conversation with a since-blocked student stays intact
--    and readable for the other person. Nothing here deletes or hides a
--    message, and `profiles` rows are not modified at all.
--
-- Idempotent: re-running is a no-op.

-- ---------------------------------------------------------------------------
-- 1 + 2. Realtime
-- ---------------------------------------------------------------------------
do $$
declare
  _table text;
begin
  foreach _table in array array['benefits', 'program_accepted_participants'] loop
    if to_regclass(format('public.%I', _table)) is null then
      raise notice 'skipping %: table not found', _table;
      continue;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = _table
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        _table
      );
      raise notice 'realtime: added public.% to supabase_realtime', _table;
    else
      raise notice 'realtime: public.% was already published', _table;
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3. Blocked students disappear from discovery
-- ---------------------------------------------------------------------------
-- One predicate, so every discovery surface can ask the same question and a
-- future surface has something to call rather than re-deriving the rule.
--
-- "Discoverable" is narrower than "exists": the account is intact, its
-- authored content is intact, and its chat history is intact. This only
-- answers whether the person should be offered to OTHER students.
create or replace function public.is_discoverable_student(_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = _user_id
      and p.deleted_at is null
      and p.banned_at is null
  )
  and public.is_student_eligible(_user_id);
$$;

grant execute on function public.is_discoverable_student(uuid) to authenticated;

-- Body preserved from 0046 (itself 0033's, plus the gender column); the only
-- change is `banned_at is null`, expressed through the helper above.
create or replace function public.list_match_candidates()
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select coalesce(jsonb_agg(row_to_json(c) order by c.created_at desc), '[]'::jsonb)
  from (
    select
      p.id, p.full_name, p.faculty, p.field_of_study, p.faculties, p.fields_of_study,
      p.degree, p.year, p.bio, p.avatar_hue, p.avatar_url, p.hobbies, p.interests,
      p.languages, p.gender, p.created_at
    from public.profiles p
    where p.id <> auth.uid()
      and public.is_discoverable_student(p.id)
    order by p.created_at desc
    limit 200
  ) c;
$$;

grant execute on function public.list_match_candidates() to authenticated;

-- Check what changed:
--
--   select count(*) from public.profiles
--   where banned_at is not null and deleted_at is null;
--
-- Those accounts keep every row they had — including their chats. Confirm:
--
--   select count(*) from public.chat_messages m
--   join public.profiles p on p.id = m.sender_id
--   where p.banned_at is not null;
