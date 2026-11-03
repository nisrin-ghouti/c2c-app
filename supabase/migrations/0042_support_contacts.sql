-- Editable "Technical Support" contacts (name + phone) shown to students
-- from Profile/Settings, editable by any admin from the admin panel.
-- Mirrors legal_documents' read-open/write-gated RPC pattern exactly.

create table if not exists public.support_contacts (
  slot        int primary key check (slot in (1, 2)),
  name        text not null default '',
  phone       text not null default '',
  updated_at  timestamptz not null default now(),
  updated_by  uuid references public.profiles (id)
);

insert into public.support_contacts (slot) values (1), (2)
on conflict (slot) do nothing;

alter table public.support_contacts enable row level security;

drop policy if exists support_contacts_read on public.support_contacts;
create policy support_contacts_read
  on public.support_contacts for select
  to authenticated
  using (true);

-- No direct writes: edits go exclusively through the admin-guarded RPC below.

create or replace function public.get_support_contacts()
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(
    jsonb_agg(jsonb_build_object('slot', c.slot, 'name', c.name, 'phone', c.phone) order by c.slot),
    '[]'::jsonb
  )
  from public.support_contacts c;
$$;

grant execute on function public.get_support_contacts() to authenticated;

create or replace function public.upsert_support_contact(_slot int, _name text, _phone text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.user_roles where user_id = auth.uid() and role = 'admin') then
    raise exception 'only an admin may edit support contacts' using errcode = '42501';
  end if;

  if _slot not in (1, 2) then
    raise exception 'unknown support contact slot: %', _slot;
  end if;

  insert into public.support_contacts (slot, name, phone, updated_at, updated_by)
  values (_slot, coalesce(_name, ''), coalesce(_phone, ''), now(), auth.uid())
  on conflict (slot) do update
    set name = excluded.name,
        phone = excluded.phone,
        updated_at = now(),
        updated_by = auth.uid();
end;
$$;

grant execute on function public.upsert_support_contact(int, text, text) to authenticated;
