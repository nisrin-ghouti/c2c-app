-- Self-service account deletion (App Store Guideline 5.1.1(v)).
--
-- Called only by the `delete-account` edge function, which runs with the
-- service-role key and resolves the caller from their own JWT. This function
-- clears every row that would otherwise block removing the user, then drops
-- the profile; the edge function deletes the `auth.users` row afterwards.
--
-- 34 foreign keys point at `profiles`. Seven are ON DELETE CASCADE and need
-- no handling here (chat_reads, device_tokens, event_attendance,
-- host_event_access.host_user_id, meeting_checkins.*, meeting_scan_tokens).
-- The other 27 are NO ACTION and would raise a foreign-key violation, so each
-- is handled explicitly below under one of two policies:
--
--   DELETE   — data that belongs to this user alone and has no value to
--              anyone else once they are gone.
--   SET NULL — records that must outlive the account: campus content other
--              students still depend on, moderation history that a user must
--              not be able to erase by deleting themselves, and a partner's
--              record of a redemption.
--
-- SET NULL requires the column to be nullable, so the block below relaxes
-- `not null` where needed. It is conditional and logs every change it makes.
--
-- Idempotent: safe to re-run.

-- Columns this function nulls must be nullable.
--
-- Applied conditionally: a column that is already nullable is left untouched,
-- and every column actually altered is reported with RAISE NOTICE. Read that
-- output — it is the exact list of schema changes this migration made, and
-- therefore exactly what `rollback_0058.sql` needs to restore. A blanket
-- `drop not null` would relax constraints invisibly.
--
-- This does weaken the invariant permanently, for all rows and future
-- inserts, not just for deleted users. That is accepted here because these
-- are authorship/audit columns whose referenced user can now legitimately
-- cease to exist, and because the alternative (a sentinel "deleted user"
-- profile) would put a phantom row in `profiles` that could surface in
-- matching candidates.
do $$
declare
  target record;
  altered int := 0;
begin
  for target in
    select * from (values
      ('benefits',          'created_by'),
      ('events',            'approved_by'),
      ('group_meetings',    'approved_by'),
      ('group_meetings',    'organizer_id'),
      ('host_event_access', 'granted_by'),
      ('legal_documents',   'updated_by'),
      ('option_lists',      'created_by'),
      ('support_contacts',  'updated_by'),
      ('surveys',           'created_by'),
      ('reports',           'reporter_id'),
      ('reports',           'reported_user_id'),
      ('digital_cards',     'redeemed_by')
    ) as t(tbl, col)
  loop
    if not exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = target.tbl
        and column_name = target.col
    ) then
      raise notice 'skipped %.% (column does not exist)', target.tbl, target.col;
      continue;
    end if;

    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = target.tbl
        and column_name = target.col
        and is_nullable = 'NO'
    ) then
      execute format(
        'alter table public.%I alter column %I drop not null',
        target.tbl, target.col
      );
      altered := altered + 1;
      raise notice 'ALTERED %.% -> nullable (rollback: alter table public.%I alter column %I set not null;)',
        target.tbl, target.col, target.tbl, target.col;
    else
      raise notice 'unchanged %.% (already nullable)', target.tbl, target.col;
    end if;
  end loop;

  raise notice 'nullability changes applied: %', altered;
end;
$$;

create or replace function public.purge_user_account(_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if _user_id is null then
    raise exception 'purge_user_account: _user_id is required';
  end if;

  -- ---------------------------------------------------------------- SET NULL
  -- Campus content authored or approved by this user stays published; only
  -- the authorship link is severed. Deleting these would remove benefits,
  -- events, surveys and option lists that other students still use.
  update public.benefits          set created_by   = null where created_by   = _user_id;
  update public.events            set approved_by  = null where approved_by  = _user_id;
  update public.group_meetings    set approved_by  = null where approved_by  = _user_id;
  update public.group_meetings    set organizer_id = null where organizer_id = _user_id;
  update public.host_event_access set granted_by   = null where granted_by   = _user_id;
  update public.legal_documents   set updated_by   = null where updated_by   = _user_id;
  update public.option_lists      set created_by   = null where created_by   = _user_id;
  update public.support_contacts  set updated_by   = null where updated_by   = _user_id;
  update public.surveys           set created_by   = null where created_by   = _user_id;

  -- Moderation history is anonymised, never destroyed: a user must not be
  -- able to erase reports filed against them by deleting their account.
  update public.reports set reporter_id      = null where reporter_id      = _user_id;
  update public.reports set reported_user_id = null where reported_user_id = _user_id;

  -- A partner's record that a card was redeemed is their audit trail, not the
  -- student's data — keep the row, drop the link.
  update public.digital_cards set redeemed_by = null where redeemed_by = _user_id;

  -- ------------------------------------------------------------------ DELETE
  -- Personal state that means nothing without its owner.
  delete from public.champions_announcements_seen where user_id = _user_id;
  delete from public.monthly_champions_history    where user_id = _user_id;
  delete from public.group_meeting_registrations  where user_id = _user_id;
  delete from public.group_meeting_scans          where scanner_id = _user_id;
  delete from public.digital_cards                where user_id = _user_id;

  -- Survey answers are deleted rather than anonymised. They can carry free
  -- text about the student, and the app makes no promise that responses are
  -- retained for analytics — the privacy-preserving choice wins.
  delete from public.survey_responses where user_id = _user_id;

  -- Meeting history: pairing records exist only to stop re-matching the same
  -- pair, and are meaningless once one side is gone.
  delete from public.meeting_pair_history where user_a = _user_id or user_b = _user_id;
  delete from public.meeting_proposals    where proposed_by = _user_id;
  update public.meeting_sessions set claimed_by = null where claimed_by = _user_id;

  -- Blocks in both directions. Keeping blocks *against* this user would
  -- preserve a dangling reference to an account that no longer exists.
  delete from public.blocks where blocker_id = _user_id or blocked_id = _user_id;

  -- Conversations are removed wholesale. A thread with one participant
  -- deleted is not useful to the other student, and retaining the deleted
  -- user's message text would defeat the point of deleting the account.
  -- Messages are cleared first in case chat_messages.chat_id is not ON DELETE
  -- CASCADE; doing it explicitly is correct either way.
  delete from public.chat_messages
  where sender_id = _user_id
     or chat_id in (
       select id from public.chats where user_a = _user_id or user_b = _user_id
     );
  delete from public.chat_reads
  where chat_id in (
    select id from public.chats where user_a = _user_id or user_b = _user_id
  );
  delete from public.chats where user_a = _user_id or user_b = _user_id;

  -- Finally the profile itself. Everything wired ON DELETE CASCADE to
  -- profiles goes with it; the edge function then removes the auth user.
  delete from public.profiles where id = _user_id;
end;
$$;

-- Only the service-role key (i.e. the edge function) may run this. No signed-in
-- client should be able to invoke it directly, for any user id.
revoke all on function public.purge_user_account(uuid) from public;
revoke all on function public.purge_user_account(uuid) from anon;
revoke all on function public.purge_user_account(uuid) from authenticated;
grant execute on function public.purge_user_account(uuid) to service_role;
