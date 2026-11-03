-- Push notifications in the RECIPIENT's language, not the author's.
--
-- Today `send-push` builds one English title/body per notification and sends
-- that same string to every device. For the types whose body is a piece of
-- user-authored content — an event or benefit title — the text the student
-- sees is whatever language the organizer happened to type into the admin
-- panel, so a Hebrew-speaking student can get an Arabic push about an event
-- whose Hebrew translation already exists in the row next to it.
--
-- Two things are missing, and both are supplied here. The Edge Function change
-- (localized copy per language, picked per device) ships with this migration;
-- see `supabase/functions/send-push/index.ts`.
--
-- 1. THE SERVER DOESN'T KNOW WHAT LANGUAGE ANYONE READS.
--    The app's locale lives only in `SharedPreferences` (`LocaleController`).
--    `device_tokens.language` gives it a home, written by
--    `register_device_token` — per DEVICE rather than per profile, which is
--    the right grain for push: it is a device that renders the notification,
--    the app already re-registers on sign-in and on a locale change, and two
--    devices of the same person can legitimately be set to two languages.
--
-- 2. THE TRANSLATIONS AREN'T IN THE PAYLOAD.
--    `events` and `benefits` have carried per-locale title columns since 0049
--    / 0054 / 0055, but `notify_event_published` and `notify_benefit_published`
--    only copy the canonical `title`, so by the time `send-push` runs the
--    translations are gone. They now travel in `notifications.data` as
--    `title_en` / `title_he` / `title_ar`, which also means the in-app
--    notification centre can localize the same rows.
--
-- Nothing is removed: `title` stays in `data` exactly as before, so an older
-- app build and the existing `send-push` both keep working against new rows,
-- and rows written before this migration keep working against the new
-- function (it falls back to `title`).
--
-- Surveys are included for the language of the FRAME ("New survey"), but a
-- survey title has no translation columns to carry — `surveys` has a single
-- `title` (0027) — so its body falls back to the stored text. Noted rather
-- than worked around: inventing a translation here would mean machine
-- translation at notify time, which is the `translate-content` function's job
-- and a separate decision.
--
-- Idempotent: re-running replaces the functions and re-adds nothing.

-- 1. Per-device language ----------------------------------------------------
alter table public.device_tokens
  add column if not exists language text;

-- Constrained to the languages the app actually ships (`SupportedLocales`), so
-- a malformed value can't quietly route someone to a missing translation
-- table. Null is allowed and means "not reported yet" — `send-push` treats it
-- as English, the app's own `SupportedLocales.fallback`.
alter table public.device_tokens
  drop constraint if exists device_tokens_language_check;
alter table public.device_tokens
  add constraint device_tokens_language_check
  check (language is null or language in ('en', 'he', 'ar'));

comment on column public.device_tokens.language is
  'App language selected on THIS device (en/he/ar), reported by '
  'register_device_token. send-push picks its copy per device from this; null '
  'means not reported yet and is treated as English.';

-- Replaces 0021's two-argument version. The new parameter is defaulted, so an
-- app build that doesn't send it keeps working (the column simply stays at
-- whatever it was).
--
-- `coalesce(_language, device_tokens.language)` on conflict: a re-registration
-- that omits the language must not wipe a language that was already reported.
create or replace function public.register_device_token(
  _token    text,
  _platform text default 'android',
  _language text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.device_tokens (token, user_id, platform, language, updated_at)
  values (
    _token,
    auth.uid(),
    coalesce(_platform, 'android'),
    nullif(_language, ''),
    now()
  )
  on conflict (token) do update
    set user_id    = auth.uid(),
        platform   = excluded.platform,
        language   = coalesce(excluded.language, device_tokens.language),
        updated_at = now();
end;
$$;

grant execute on function public.register_device_token(text, text, text) to authenticated;

-- 0021's two-argument signature is a DIFFERENT function as far as Postgres is
-- concerned (defaults don't merge overloads), so it would still be resolved by
-- a two-argument call and would still write no language. Drop it so there is
-- exactly one implementation.
drop function if exists public.register_device_token(text, text);

-- 2. Translations in the notification payload --------------------------------
-- Skip soft-deleted profiles while we're here: they can hold device tokens
-- until the row is purged, and a deleted account has no business being
-- notified. Same set the survey fan-out (0074) uses.
create or replace function public.notify_all_students(
  _type   text,
  _data   jsonb,
  _except uuid default null
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.notifications (user_id, type, data)
  select p.id, _type, _data
  from public.profiles p
  where (_except is null or p.id <> _except)
    and p.deleted_at is null;
$$;

-- Event published — body preserved from 0014, plus the three title columns.
create or replace function public.notify_event_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and old.approval_status is not distinct from new.approval_status then
    return new;
  end if;

  if new.approval_status <> 'approved' then
    return new;
  end if;

  perform public.notify_all_students(
    'event_published',
    jsonb_build_object(
      'event_id',  new.id,
      'title',     new.title,
      'title_en',  new.title_en,
      'title_he',  new.title_he,
      'title_ar',  new.title_ar,
      'starts_at', new.starts_at,
      'points',    new.points
    ),
    new.created_by
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_event_published on public.events;
create trigger trg_notify_event_published
  after insert or update of approval_status on public.events
  for each row
  execute function public.notify_event_published();

-- Benefit published — body preserved from 0066 (which is 0014's plus the
-- `_except` argument), plus the three title columns.
create or replace function public.notify_benefit_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and old.active is not distinct from new.active then
    return new;
  end if;

  if new.active is not true then
    return new;
  end if;

  perform public.notify_all_students(
    'benefit_published',
    jsonb_build_object(
      'benefit_id', new.id,
      'title',      new.title,
      'title_en',   new.title_en,
      'title_he',   new.title_he,
      'title_ar',   new.title_ar,
      'points',     new.point_cost,
      'business',   new.partner_business_name
    ),
    new.created_by
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_benefit_published on public.benefits;
create trigger trg_notify_benefit_published
  after insert or update of active on public.benefits
  for each row
  execute function public.notify_benefit_published();

-- Event approved/rejected -> the host. Body preserved from 0014, plus titles,
-- so the decision push reads in the host's own language too.
create or replace function public.notify_event_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.approval_status is not distinct from new.approval_status then
    return new;
  end if;

  if new.approval_status not in ('approved', 'rejected') then
    return new;
  end if;

  insert into public.notifications (user_id, type, data)
  values (
    new.created_by,
    'event_decision',
    jsonb_build_object(
      'event_id', new.id,
      'title',    new.title,
      'title_en', new.title_en,
      'title_he', new.title_he,
      'title_ar', new.title_ar,
      'status',   new.approval_status,
      'reason',   new.rejection_reason
    )
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_event_decision on public.events;
create trigger trg_notify_event_decision
  after update of approval_status on public.events
  for each row
  execute function public.notify_event_decision();

-- Check what a device reported, and what a payload now carries:
--
--   select platform, language, count(*) from public.device_tokens
--   group by platform, language;
--
--   select type, data from public.notifications
--   order by created_at desc limit 5;
