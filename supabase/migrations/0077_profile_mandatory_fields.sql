-- Make the seven mandatory profile fields mandatory server-side too.
--
-- First name, last name, field of study, faculty, degree level, year of study
-- and gender are now required both during onboarding and when editing a
-- profile. The client enforces all seven (`CompleteProfileScreen`,
-- `EditProfileScreen`, and `Profile.isComplete` which the router's gate reads),
-- and this is the backstop behind them: a stale build, a hand-rolled request or
-- a direct PostgREST call must not be able to write a profile that the app
-- would then treat as incomplete and bounce the user out of.
--
-- Deliberately narrow, because `profiles` is written from more than one place
-- and this must not become a new way for an unrelated save to fail:
--
--   * SELF-UPDATES ONLY (`auth.uid() = new.id`). The admin console's
--     `admin_update_profile` (0051) edits someone else's row, so it is
--     unaffected.
--   * STUDENT-ELIGIBLE ACCOUNTS ONLY (`is_student_eligible`, 0033). Admin and
--     host accounts are hard-gated out of the student app by the router, so
--     their profiles were never held to this rule and an admin editing their
--     own row in the console must not start failing because they have no year
--     of study.
--   * NOT ON INSERT. `ensureProfileExists` creates a bare row at sign-up, by
--     design — the whole point of the Complete-Profile gate is that the row
--     exists and is then filled in.
--   * NOT WHEN SOFT-DELETING. An account being closed (`deleted_at`) is not
--     being edited.
--
-- Both the array columns and their legacy singular mirrors are accepted for
-- faculty and field of study. `saveProfile` writes both (`faculties` +
-- `faculty`), Matches still reads the singular ones, and `admin_update_profile`
-- writes only the singular ones — so requiring the array form specifically
-- would reject writes that are perfectly complete.
--
-- EXISTING ROWS ARE NOT TOUCHED. No backfill, no NOT NULL constraints: a
-- profile saved under the old rule (name + field of study) stays exactly as it
-- is, and the router sends that user through Complete Profile the next time
-- they open the app — where the client now requires all seven before it will
-- submit. Adding column constraints instead would have made every such row
-- invalid in place, which breaks reads, not just writes.
--
-- Idempotent: re-running replaces the function and the trigger.

-- 1. The rule, as one function ---------------------------------------------
-- Mirrors `Profile.isComplete` in lib/features/auth/domain/entities/profile.dart.
-- The two have to agree: this one decides whether a write is allowed, that one
-- decides whether the user is let past the gate, and a disagreement means
-- either a save that bounces straight back to Complete Profile or a profile
-- that can never be saved at all.
create or replace function public.profile_has_mandatory_fields(
  _profile public.profiles
)
returns boolean
language sql
immutable
set search_path to 'public'
as $$
  select
    -- First AND last name. The schema has only `full_name`, so "last name
    -- present" is a second word — the same split both profile forms use to
    -- prefill their two inputs.
    array_length(
      array_remove(regexp_split_to_array(btrim(coalesce(_profile.full_name, '')), '\s+'), ''),
      1
    ) >= 2
    and (
      coalesce(array_length(_profile.fields_of_study, 1), 0) > 0
      or coalesce(btrim(_profile.field_of_study), '') <> ''
    )
    and (
      coalesce(array_length(_profile.faculties, 1), 0) > 0
      or coalesce(btrim(_profile.faculty), '') <> ''
    )
    and coalesce(btrim(_profile.degree), '') <> ''
    and _profile.year is not null
    and coalesce(btrim(_profile.gender), '') <> '';
$$;

-- 2. The guard --------------------------------------------------------------
create or replace function public.enforce_profile_mandatory_fields()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  -- Not the owner editing their own row -> not this rule's business.
  if auth.uid() is null or auth.uid() <> new.id then
    return new;
  end if;

  -- Closing the account, not editing it.
  if new.deleted_at is not null then
    return new;
  end if;

  -- Admin/host-only accounts are gated out of the student app entirely.
  if not public.is_student_eligible(new.id) then
    return new;
  end if;

  if public.profile_has_mandatory_fields(new) then
    return new;
  end if;

  -- Message kept machine-readable at the front so a client can special-case
  -- it; the app surfaces its own localized copy and never shows this text.
  raise exception 'profile_incomplete: first name, last name, field of study, '
    'faculty, degree, year of study and gender are all required'
    using errcode = 'check_violation';
end;
$$;

drop trigger if exists trg_enforce_profile_mandatory_fields on public.profiles;
create trigger trg_enforce_profile_mandatory_fields
  before update on public.profiles
  for each row
  execute function public.enforce_profile_mandatory_fields();

-- How many existing profiles the client will now route through Complete
-- Profile on their next sign-in:
--
--   select count(*) from public.profiles p
--   where p.deleted_at is null
--     and public.is_student_eligible(p.id)
--     and not public.profile_has_mandatory_fields(p);
--
-- And which field each one is missing:
--
--   select id, full_name, faculties, faculty, fields_of_study,
--          field_of_study, degree, year, gender
--   from public.profiles p
--   where p.deleted_at is null
--     and public.is_student_eligible(p.id)
--     and not public.profile_has_mandatory_fields(p)
--   limit 50;
