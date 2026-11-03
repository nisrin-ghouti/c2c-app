-- Rollback for 0058_purge_user_account.sql.
--
-- Step 1 alone fully disables account deletion: with the function gone the
-- edge function's RPC call fails and no data can be purged. Run step 1 if you
-- just want to stop deletion working.
--
-- Step 2 restores column nullability. Only run the statements that
-- `preflight_0058.sql` reported as `is_nullable = 'NO'` — those are the only
-- columns 0058 actually changed. Re-adding `not null` to a column that was
-- already nullable would impose a constraint the schema never had.
--
-- Note: `set not null` FAILS if the column now contains nulls. If any account
-- has been deleted since 0058 ran, its rows were nulled deliberately and that
-- is not something to undo — clean or reassign those rows first, or leave the
-- column nullable.

-- ---------------------------------------------------------------- Step 1
drop function if exists public.purge_user_account(uuid);

-- ---------------------------------------------------------------- Step 2
-- CONFIRMED against production: of the 12 columns 0058 considered, exactly
-- these three were NOT NULL beforehand and were therefore altered. The other
-- nine were already nullable and must be left alone — re-adding `not null`
-- to them would impose a constraint the schema never had.
--
-- `set not null` FAILS if the column now contains nulls. Any account deleted
-- since 0058 ran will have nulled these deliberately; that is not something to
-- undo. Clean or reassign those rows first, or leave the columns nullable.

alter table public.group_meetings alter column organizer_id     set not null;
alter table public.reports        alter column reporter_id      set not null;
alter table public.reports        alter column reported_user_id set not null;
