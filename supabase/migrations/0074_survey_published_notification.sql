-- "New survey" notifications: fire for the right people, exactly once.
--
-- The chain already exists end to end — 0036 added `notify_survey_published`,
-- `notifications.type` allows `survey_published` (0036, restated by 0066),
-- `send-push` has a `survey_published` case, and the app renders and routes
-- the type. So this is not a new feature; it is the two defects that made the
-- existing one behave wrongly, plus the push tap destination on the app side.
--
-- 1. IT NOTIFIED EVERYONE, IGNORING THE SURVEY'S TARGETING.
--    `notify_survey_published` calls `notify_all_students`, which is one row
--    per profile. But a survey can be scoped to faculties through
--    `survey_targets` — that's what `list_available_surveys` and
--    `get_survey_detail` both filter on — so students were told about surveys
--    they then couldn't see at all.
--
--    This is not fixable from a row-level AFTER trigger, which is the second
--    half of the defect: `admin_create_survey` inserts the survey row FIRST
--    and its `survey_targets` rows after, so at trigger time the targeting
--    does not exist yet and every survey looks untargeted.
--    `admin_update_survey` is worse — it DELETEs the target rows and
--    re-inserts them, so the trigger sees a transient empty set.
--
--    Fixed by making the trigger a DEFERRABLE CONSTRAINT trigger, which runs
--    at COMMIT instead of at statement time. By then the admin RPC has
--    finished writing its targets and the fan-out can read them. Doing it this
--    way means `admin_create_survey`/`admin_update_survey` are not touched at
--    all — those are re-declared by several migrations (0027, 0039) and belong
--    to the admin console's own surface.
--
-- 2. IT COULD NOTIFY THE SAME SURVEY TWICE.
--    The guard was `old.is_published is not distinct from new.is_published`,
--    which correctly ignores an ordinary edit but re-notifies on every
--    unpublish/republish cycle — and `admin_update_survey` writes
--    `is_published` on EVERY save, so any save that happened to flip the flag
--    counted as a new publication. Replaced with a one-way marker column:
--    once a survey has notified, it never notifies again.
--
-- Recipients, matching what the student can actually act on:
--   * faculty targeting respected (no target rows = everyone, same rule as
--     `list_available_surveys`);
--   * the creator excluded, as the event and benefit fan-outs already do;
--   * admin/host-only accounts excluded (`is_student_eligible`) — they are
--     hard-gated out of the student app by the router, so a survey push would
--     open onto the "not available" screen;
--   * soft-deleted profiles excluded.
--
-- Idempotent: re-running replaces the function and trigger and inserts
-- nothing. Surveys already published before this migration are marked as
-- already-notified so applying it doesn't fan out a backlog.

-- 1. The dedupe marker ------------------------------------------------------
alter table public.surveys
  add column if not exists published_notified_at timestamptz;

comment on column public.surveys.published_notified_at is
  'When the "new survey" fan-out ran for this survey. Set once, by '
  'notify_survey_published_rows(); a non-null value is what stops an edit, or '
  'an unpublish/republish cycle, from notifying the campus again.';

-- Backfill: anything already published predates this mechanism and its
-- students have either been notified already (0036) or never will be. Either
-- way, do not fan out a backlog the first time this migration runs.
update public.surveys
  set published_notified_at = coalesce(published_notified_at, now())
where is_published
  and published_notified_at is null;

-- 2. The fan-out ------------------------------------------------------------
-- Takes a survey id rather than a trigger row because a constraint trigger's
-- NEW is the row as it was written, and by commit time the targeting it needs
-- lives in another table — so everything is re-read here.
create or replace function public.notify_survey_published_rows(_survey_id uuid)
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  _survey public.surveys%rowtype;
  _count  integer;
begin
  select * into _survey from public.surveys where id = _survey_id;
  if not found then
    return 0;
  end if;
  if not _survey.is_published then
    return 0;
  end if;
  if _survey.published_notified_at is not null then
    return 0;
  end if;

  -- Claim the survey before inserting. Conditional on the marker still being
  -- null, so two concurrent commits can't both fan out: the loser updates no
  -- row and returns without writing notifications.
  update public.surveys
    set published_notified_at = now()
  where id = _survey_id
    and published_notified_at is null;
  if not found then
    return 0;
  end if;

  insert into public.notifications (user_id, type, data)
  select
    p.id,
    'survey_published',
    jsonb_build_object(
      'survey_id', _survey.id,
      'title',     _survey.title,
      'points',    _survey.points
    )
  from public.profiles p
  where p.deleted_at is null
    and (_survey.created_by is null or p.id <> _survey.created_by)
    and public.is_student_eligible(p.id)
    -- Same targeting predicate as `list_available_surveys`: no target rows
    -- means the survey is for everyone.
    and (
      not exists (
        select 1 from public.survey_targets t where t.survey_id = _survey.id
      )
      or exists (
        select 1 from public.survey_targets t
        where t.survey_id = _survey.id
          and t.target_type = 'faculty'
          and t.target_value = any(coalesce(p.faculties, array[]::text[]))
      )
    );

  get diagnostics _count = row_count;
  return _count;
end;
$$;

-- 3. The trigger ------------------------------------------------------------
-- A CONSTRAINT trigger so it runs at COMMIT (see the note at the top).
-- Constraint triggers are always row-level AFTER and cannot use
-- `update of <column>`, so the column guard moves into the body — which is
-- where it has to be anyway, since the real guard is the marker column.
create or replace function public.notify_survey_published()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.is_published is not true then
    return new;
  end if;
  if new.published_notified_at is not null then
    return new;
  end if;

  -- Never let the fan-out take the survey down with it.
  --
  -- This is a DEFERRED trigger, so it runs at COMMIT — after
  -- `admin_create_survey` has already returned `{"status":"ok"}` to the admin
  -- console. An exception escaping here would roll the whole transaction back,
  -- and the console would be told its save failed on a survey that was
  -- otherwise written correctly. Publishing a survey must not depend on the
  -- notification succeeding.
  --
  -- The block's own rollback is what makes this safe to swallow: the
  -- `published_notified_at` claim is written inside
  -- `notify_survey_published_rows`, so a failure un-claims the survey too and
  -- the next write that touches it tries again, rather than leaving it marked
  -- as notified with nothing sent.
  begin
    perform public.notify_survey_published_rows(new.id);
  exception when others then
    raise warning 'survey_published fan-out failed for survey % (%): %',
      new.id, sqlstate, sqlerrm;
  end;

  return new;
end;
$$;

-- The old statement-time trigger from 0036 has to go, or both would fire.
drop trigger if exists trg_notify_survey_published on public.surveys;

do $$
begin
  -- `create constraint trigger` has no `if not exists`, so drop first.
  execute 'drop trigger if exists trg_notify_survey_published_deferred on public.surveys';
  execute $trg$
    create constraint trigger trg_notify_survey_published_deferred
      after insert or update on public.surveys
      deferrable initially deferred
      for each row
      execute function public.notify_survey_published()
  $trg$;
end $$;

-- Check what a publish produced:
--
--   select type, count(*) from public.notifications
--   where data->>'survey_id' = '<id>' group by type;
--
--   select id, title, is_published, published_notified_at from public.surveys
--   order by created_at desc limit 10;
