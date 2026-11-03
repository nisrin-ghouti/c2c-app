-- Editable Privacy Policy and Terms & Conditions documents.
--
-- Separate from the `policies` table used by the sign-up agreement gate: that
-- table drives a one-time "I agree" flow with versioning and per-user consent
-- rows. These two are living reference documents the super admin edits in
-- place and every user can read from Settings — no consent tracking, no
-- version bump on each edit.

create table if not exists public.legal_documents (
  -- 'privacy' | 'terms'. The kind IS the primary key — there is exactly one of
  -- each, edited in place.
  kind        text primary key check (kind in ('privacy', 'terms')),
  title       text not null default '',
  body        text not null default '',
  updated_at  timestamptz not null default now(),
  updated_by  uuid references public.profiles (id)
);

-- Seed empty rows so the viewer and editor always have something to load.
insert into public.legal_documents (kind, title)
values ('privacy', 'Privacy Policy'),
       ('terms',   'Terms & Conditions')
on conflict (kind) do nothing;

alter table public.legal_documents enable row level security;

-- Everyone signed in may read both documents.
drop policy if exists legal_documents_read on public.legal_documents;
create policy legal_documents_read
  on public.legal_documents for select
  to authenticated
  using (true);

-- No direct writes: edits go exclusively through the super-admin-guarded RPC
-- below, so there is intentionally no INSERT/UPDATE policy.

-- Read RPC — returns one document, or null if the kind is unknown.
create or replace function public.get_legal_document(_kind text)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select case when d.kind is null then null else
    jsonb_build_object(
      'kind',       d.kind,
      'title',      d.title,
      'body',       d.body,
      'updated_at', d.updated_at
    )
  end
  from public.legal_documents d
  where d.kind = _kind;
$$;

grant execute on function public.get_legal_document(text) to authenticated;

-- Write RPC — super admin only. Returns true on success, raises otherwise.
-- The is_super_admin check reads `profiles.is_super_admin`, matching how the
-- rest of the app identifies the super admin.
create or replace function public.upsert_legal_document(
  _kind  text,
  _title text,
  _body  text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and coalesce(is_super_admin, false)
  ) then
    raise exception 'only the super admin may edit legal documents'
      using errcode = '42501';
  end if;

  if _kind not in ('privacy', 'terms') then
    raise exception 'unknown legal document kind: %', _kind;
  end if;

  insert into public.legal_documents (kind, title, body, updated_at, updated_by)
  values (_kind, coalesce(_title, ''), coalesce(_body, ''), now(), auth.uid())
  on conflict (kind) do update
    set title = excluded.title,
        body = excluded.body,
        updated_at = now(),
        updated_by = auth.uid();
end;
$$;

grant execute on function public.upsert_legal_document(text, text, text) to authenticated;
