-- Organizer Name becomes a predefined list instead of free text.
--
-- `events.organizer_name` has always been a free-text field typed into the
-- event form, so the same organizer arrived spelled three different ways and
-- nothing could group by it. This moves it onto the existing `option_lists`
-- mechanism — the same one already behind faculties, event categories and
-- campus locations — so admins curate the allowed values in the admin
-- console's "Possible Lists" screen and the event form offers a dropdown.
--
-- Nothing about the `events` table changes: `organizer_name` stays text, and
-- every existing event keeps the value it already has. The admin form shows a
-- stored value that isn't (yet) on the list as a selected-but-unlisted entry
-- rather than silently clearing it, so editing an old event doesn't wipe its
-- organizer. Adding that value to the list in "Possible Lists" is all it takes
-- to regularise it.
--
-- Idempotent: re-running recreates the constraint and inserts nothing new.

-- 1. Allow the new list_type ------------------------------------------------
-- The CHECK constraint enumerates every permitted list_type, so a new one has
-- to be added here before any row can be inserted. The list below is 0053's
-- plus 'event_organizer' — it must keep naming every type already in use, or
-- re-running this would reject rows that are already stored.
alter table public.option_lists
  drop constraint if exists option_lists_list_type_check;

alter table public.option_lists
  add constraint option_lists_list_type_check
  check (list_type = any (array[
    'faculty', 'field_of_study', 'degree', 'hobby', 'interest',
    'language', 'event_category', 'benefit_category', 'campus_location',
    'event_organizer'
  ]));

-- 2. Seed from the organizer names already in use ---------------------------
-- Rather than inventing a starter list, adopt whatever hosts have already
-- typed: every distinct non-empty `organizer_name` becomes a list entry, so no
-- existing event is left pointing at an unlisted organizer on day one.
--
-- `label` is the canonical (English) value events store, matching how
-- `event_category` works. Hebrew/Arabic labels are left null here — an admin
-- fills them in from "Possible Lists", and the form falls back to `label`
-- until they do.
insert into public.option_lists (list_type, label, sort_order, active)
select
  'event_organizer',
  trimmed.label,
  row_number() over (order by trimmed.label),
  true
from (
  select distinct btrim(e.organizer_name) as label
  from public.events e
  where e.organizer_name is not null
    and btrim(e.organizer_name) <> ''
) as trimmed
where not exists (
  select 1 from public.option_lists o
  where o.list_type = 'event_organizer'
    and o.label = trimmed.label
);

-- 3. A baseline entry, so the dropdown is never empty on a fresh project ----
insert into public.option_lists (list_type, label, label_he, label_ar, sort_order, active)
select 'event_organizer', 'Student Union', 'אגודת הסטודנטים', 'اتحاد الطلاب', 1000, true
where not exists (
  select 1 from public.option_lists
  where list_type = 'event_organizer' and label = 'Student Union'
);
