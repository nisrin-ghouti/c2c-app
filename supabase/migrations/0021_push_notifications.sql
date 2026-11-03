-- Push-notification plumbing + in-app chat notifications.
--
-- Design: push is driven off the `notifications` table. Every notification
-- type already inserts a row there (points, events, benefits, approvals,
-- reports, meetings — migrations 0014 etc.), so a single Database Webhook on
-- `notifications` INSERT → the `send-push` Edge Function delivers push for ALL
-- of them. This migration adds the two missing pieces:
--   1. a place to store each device's FCM token, and
--   2. a `new_message` notification when a chat message arrives (so chat shows
--      up both in the in-app bell AND, via the webhook, as a push).

-- 1. Device tokens ----------------------------------------------------------
create table if not exists public.device_tokens (
  token       text primary key,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  platform    text not null default 'android' check (platform in ('android', 'ios', 'web')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists device_tokens_user_idx on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

-- A user can see/manage only their own tokens; the Edge Function reads all via
-- the service-role key (which bypasses RLS).
drop policy if exists device_tokens_own on public.device_tokens;
create policy device_tokens_own
  on public.device_tokens for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Register (or refresh) the caller's token. Upsert keyed on the token so the
-- same device re-registering just updates ownership/timestamp — and a token
-- that moved to a new account (reinstall, account switch) is reassigned.
create or replace function public.register_device_token(_token text, _platform text default 'android')
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.device_tokens (token, user_id, platform, updated_at)
  values (_token, auth.uid(), coalesce(_platform, 'android'), now())
  on conflict (token) do update
    set user_id = auth.uid(),
        platform = excluded.platform,
        updated_at = now();
end;
$$;

grant execute on function public.register_device_token(text, text) to authenticated;

-- Drop the caller's token (on logout, or when FCM reports it stale).
create or replace function public.unregister_device_token(_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.device_tokens where token = _token and user_id = auth.uid();
end;
$$;

grant execute on function public.unregister_device_token(text) to authenticated;

-- 2. Chat message → in-app notification -------------------------------------
-- Inserts a `new_message` notification for the *recipient* (the other chat
-- member) whenever a message is sent. The client already renders this type;
-- the push webhook then turns it into a device push. Meeting-proposal messages
-- are skipped here — they have their own `meeting_proposal` notification.
create or replace function public.notify_new_chat_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sender_name text;
begin
  if new.message_type is not distinct from 'meeting_proposal' then
    return new;
  end if;

  select full_name into v_sender_name from public.profiles where id = new.sender_id;

  insert into public.notifications (user_id, type, data)
  select m,
         'new_message',
         jsonb_build_object(
           'chat_id',     new.chat_id,
           'sender_id',   new.sender_id,
           'sender_name', coalesce(v_sender_name, ''),
           'preview',     left(coalesce(new.body, ''), 120)
         )
  from public.chat_member_ids(new.chat_id) m
  where m <> new.sender_id;

  return new;
end;
$$;

drop trigger if exists trg_notify_new_chat_message on public.chat_messages;
create trigger trg_notify_new_chat_message
  after insert on public.chat_messages
  for each row
  execute function public.notify_new_chat_message();

-- Realtime so the in-app bell/badge updates live (safe if already added).
do $$
begin
  begin
    alter publication supabase_realtime add table public.notifications;
  exception when duplicate_object then null;
  end;
end $$;
