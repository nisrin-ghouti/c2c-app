-- Adds the `host_group_manager` value to the `app_role` enum.
--
-- THIS MIGRATION DOES NOTHING ELSE, AND THAT IS DELIBERATE.
--
-- Postgres will not let a newly added enum value be *used* by the same
-- transaction that added it:
--
--   ERROR: unsafe use of new value "host_group_manager" of enum type app_role
--
-- Everything that references the new role — tables, helper functions,
-- policies, triggers — therefore lives in 0081, which must be run as a
-- separate statement batch after this one has committed. Running them as one
-- script fails on the first function body that casts to the new value.
--
-- Run this on its own, confirm it succeeded, then run 0081.
--
-- Idempotent: `if not exists` makes a re-run a no-op rather than an error.

alter type public.app_role add value if not exists 'host_group_manager';
