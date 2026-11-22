-- Push titles in the student's language when the stored translation is missing.
--
-- send-push already picks en/he/ar per device (0075). It can only use a
-- translation that was copied into notifications.data. Two cases arrive
-- without one:
--
--   * a survey title has no translation columns at all;
--   * an event or benefit can be approved in the same transaction that
--     inserts it, and the admin app fills title_en/title_he/title_ar only
--     after that commit returns. The push then falls back to whatever
--     language the organizer typed.
--
-- This cache lets send-push translate that one canonical title once per
-- distinct string (a campus-wide fan-out is one row per student, so without
-- the cache the same title would be sent to Google once per recipient) and
-- then still render each device in its own language. A translation the
-- payload already carries is never overwritten.
--
-- Chat message text is not cached or translated here. That body is the
-- sender's own words, not a title we authored.
--
-- The table is written only by send-push, which uses the service role.
-- RLS is on and no policy is granted, so the Data API cannot read it.

create table if not exists public.push_title_translations (
  source_key text primary key,
  source_text text not null,
  title_en text,
  title_he text,
  title_ar text,
  claimed_at timestamptz,
  ready_at timestamptz
);

comment on table public.push_title_translations is
  'Machine translations of a notification title, keyed by md5(source text). '
  'send-push claims a row, translates once, and every other recipient of the '
  'same title waits for that result. One row per distinct title, not per student.';

alter table public.push_title_translations enable row level security;

revoke all on table public.push_title_translations from public;
revoke all on table public.push_title_translations from anon, authenticated;

-- Claim the right to translate this string. Returns:
--   translate — this caller should call Google and then save
--   ready     — a finished translation is already stored
--   wait      — another caller is translating it right now
--   skip      — empty source
-- A claim older than 20s is treated as abandoned so a crashed call does not
-- block the title forever.
create or replace function public.claim_push_title_translation(_source text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  _status text;
  _key text;
begin
  if _source is null or btrim(_source) = '' then
    return 'skip';
  end if;

  _key := md5(_source);

  with upsert as (
    insert into public.push_title_translations (source_key, source_text, claimed_at)
    values (_key, _source, now())
    on conflict (source_key) do update
      set claimed_at = now()
      where public.push_title_translations.ready_at is null
        and (
          public.push_title_translations.claimed_at is null
          or public.push_title_translations.claimed_at < now() - interval '20 seconds'
        )
    returning source_key
  )
  select case
    when exists (select 1 from upsert) then 'translate'
    when exists (
      select 1
      from public.push_title_translations t
      where t.source_key = _key
        and t.ready_at is not null
        and t.title_en is not null
        and t.title_he is not null
        and t.title_ar is not null
    ) then 'ready'
    else 'wait'
  end
  into _status;

  return _status;
end;
$$;

create or replace function public.get_push_title_translation(_source text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'ready',
          t.ready_at is not null
          and t.title_en is not null
          and t.title_he is not null
          and t.title_ar is not null,
        'title_en', t.title_en,
        'title_he', t.title_he,
        'title_ar', t.title_ar
      )
      from public.push_title_translations t
      where t.source_key = md5(_source)
    ),
    jsonb_build_object('ready', false)
  );
$$;

create or replace function public.save_push_title_translation(
  _source text,
  _title_en text,
  _title_he text,
  _title_ar text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if _source is null or btrim(_source) = '' then
    return;
  end if;
  if coalesce(btrim(_title_en), '') = ''
     or coalesce(btrim(_title_he), '') = ''
     or coalesce(btrim(_title_ar), '') = '' then
    return;
  end if;

  update public.push_title_translations
    set title_en = _title_en,
        title_he = _title_he,
        title_ar = _title_ar,
        ready_at = now()
  where source_key = md5(_source);
end;
$$;

create or replace function public.release_push_title_translation(_source text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.push_title_translations
    set claimed_at = null
  where source_key = md5(_source)
    and ready_at is null;
$$;

revoke all on function public.claim_push_title_translation(text) from public, anon, authenticated;
revoke all on function public.get_push_title_translation(text) from public, anon, authenticated;
revoke all on function public.save_push_title_translation(text, text, text, text) from public, anon, authenticated;
revoke all on function public.release_push_title_translation(text) from public, anon, authenticated;

grant execute on function public.claim_push_title_translation(text) to service_role;
grant execute on function public.get_push_title_translation(text) to service_role;
grant execute on function public.save_push_title_translation(text, text, text, text) to service_role;
grant execute on function public.release_push_title_translation(text) to service_role;
