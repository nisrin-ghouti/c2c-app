-- Unread message counts for the chat list — no read-tracking existed at all
-- before this (no `read_at` column, no per-user "last seen" marker).

create table if not exists public.chat_reads (
  chat_id      uuid not null references public.chats (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (chat_id, user_id)
);

alter table public.chat_reads enable row level security;

drop policy if exists chat_reads_read_own on public.chat_reads;
create policy chat_reads_read_own
  on public.chat_reads for select
  to authenticated
  using (user_id = auth.uid());

-- No direct writes: always through `mark_chat_read` below (SECURITY DEFINER),
-- consistent with every other write path in this schema.

create or replace function public.mark_chat_read(_chat_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.chats
    where id = _chat_id and (user_a = auth.uid() or user_b = auth.uid())
  ) then
    return;
  end if;

  insert into public.chat_reads (chat_id, user_id, last_read_at)
  values (_chat_id, auth.uid(), now())
  on conflict (chat_id, user_id) do update set last_read_at = now();
end;
$$;

grant execute on function public.mark_chat_read(uuid) to authenticated;

-- `list_my_chats` return shape changed (added unread_count) — drop first,
-- Postgres requires that before CREATE OR REPLACE can change OUT params.
drop function if exists public.list_my_chats();

create function public.list_my_chats()
returns table (
  chat_id uuid,
  other_user_id uuid,
  other_full_name text,
  other_avatar_url text,
  other_avatar_hue integer,
  last_message_body text,
  last_message_at timestamptz,
  last_message_sender_id uuid,
  unread_count integer
)
language sql
security definer
set search_path to 'public'
as $$
  select
    c.id,
    other.id,
    other.full_name,
    other.avatar_url,
    other.avatar_hue,
    lm.body,
    lm.created_at,
    lm.sender_id,
    coalesce(uc.unread, 0)::int
  from chats c
  join profiles other on other.id = (case when c.user_a = auth.uid() then c.user_b else c.user_a end)
  left join lateral (
    select body, created_at, sender_id from chat_messages m
    where m.chat_id = c.id order by m.created_at desc limit 1
  ) lm on true
  left join chat_reads cr on cr.chat_id = c.id and cr.user_id = auth.uid()
  left join lateral (
    select count(*) as unread
    from chat_messages m
    where m.chat_id = c.id
      and m.sender_id <> auth.uid()
      and m.created_at > coalesce(cr.last_read_at, 'epoch'::timestamptz)
  ) uc on true
  where c.user_a = auth.uid() or c.user_b = auth.uid()
  order by coalesce(lm.created_at, c.created_at) desc;
$$;

grant execute on function public.list_my_chats() to authenticated;
