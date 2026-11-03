-- Events: direct image upload, admin self-approval, and pending-approval alerts.
--
-- Deliberately implemented as TRIGGERS on `events` rather than by editing
-- `create_event_or_program`. That RPC takes a jsonb payload and its body isn't
-- in this repo; a trigger enforces both rules for every write path (the RPC,
-- a future admin tool, a manual SQL insert) and can't be bypassed by one code
-- path forgetting to call it.

-- 1. Event Profile columns required by the spec ------------------------------
-- The spec's Event Profile lists an organizer description and an external link
-- (Instagram/website/Facebook); neither existed on `events`.
alter table public.events
  add column if not exists organizer_description text,
  add column if not exists external_link         text;

-- 2. Storage bucket for event images ----------------------------------------
-- Public-read like `benefit-images` (0012): event art is shown to every
-- student, including on the pre-login-ish home dashboard, so signed URLs would
-- buy nothing and cost a round trip per image.
insert into storage.buckets (id, name, public)
values ('event-images', 'event-images', true)
on conflict (id) do nothing;

drop policy if exists event_images_public_read  on storage.objects;
drop policy if exists event_images_admin_write  on storage.objects;

create policy event_images_public_read
  on storage.objects for select
  using (bucket_id = 'event-images');

-- Hosts create events too, not just admins — so writes are open to any
-- authenticated user. The bucket only ever holds event art, and an
-- unapproved event is invisible to students regardless of its image.
create policy event_images_admin_write
  on storage.objects for all
  to authenticated
  using (bucket_id = 'event-images')
  with check (bucket_id = 'event-images');

-- 3. Admins don't approve their own events ----------------------------------
-- BEFORE INSERT so it overrides whatever approval_status the caller supplied.
create or replace function public.auto_approve_admin_events()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- created_by (not auth.uid()) so the rule follows the *author*, which is
  -- what "their own events" means — even if an admin is created on someone
  -- else's behalf by a future tool.
  if public.is_admin(new.created_by) then
    new.approval_status := 'approved';
    new.rejection_reason := null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_auto_approve_admin_events on public.events;
create trigger trg_auto_approve_admin_events
  before insert on public.events
  for each row
  execute function public.auto_approve_admin_events();

-- 4. Notify admins when an event is waiting for approval --------------------
-- `notifications.type` may be either a text column with a CHECK constraint or
-- a Postgres enum, depending on how the base schema was authored. Handle both
-- rather than guessing, so this migration doesn't fail on an unseen schema.
do $$
declare
  type_name text;
  con_name  text;
begin
  select t.typname into type_name
  from pg_attribute a
  join pg_type t on t.oid = a.atttypid
  where a.attrelid = 'public.notifications'::regclass
    and a.attname  = 'type'
    and a.attnum   > 0;

  if type_name is distinct from 'text' and type_name is distinct from 'varchar' then
    -- Enum column: add the new label if it isn't already there.
    execute format(
      'alter type public.%I add value if not exists %L',
      type_name, 'event_pending_approval'
    );
  else
    -- Text column: widen any CHECK constraint that constrains `type`.
    select conname into con_name
    from pg_constraint
    where conrelid = 'public.notifications'::regclass
      and contype  = 'c'
      and pg_get_constraintdef(oid) ilike '%type%';

    if con_name is not null then
      execute format('alter table public.notifications drop constraint %I', con_name);
      alter table public.notifications
        add constraint notifications_type_check
        check (type in (
          'points_earned',
          'new_message',
          'meeting_proposal',
          'event_pending_approval'
        ));
    end if;
  end if;
end
$$;

create or replace function public.notify_admins_event_pending()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.approval_status <> 'pending' then
    return new;
  end if;

  -- Fan out one row per admin. The author is excluded — after step 2 an
  -- admin's own event is never pending, but this keeps the rule explicit if
  -- that ever changes.
  insert into public.notifications (user_id, type, data)
  select r.user_id,
         'event_pending_approval',
         jsonb_build_object(
           'event_id',  new.id,
           'title',     new.title,
           'organizer', new.organizer_name,
           'starts_at', new.starts_at
         )
  from public.user_roles r
  where r.role = 'admin'::app_role
    and r.user_id <> new.created_by;

  return new;
end;
$$;

drop trigger if exists trg_notify_admins_event_pending on public.events;
create trigger trg_notify_admins_event_pending
  after insert on public.events
  for each row
  execute function public.notify_admins_event_pending();
