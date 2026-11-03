-- Lets the admin panel offer co-hosts while an event is still being created,
-- not only when editing one that already exists.
--
-- `search_host_candidates` (0062) authorizes the caller by asking
-- `can_manage_event_hosts(_event_id)` — "are you this event's creator?". That
-- question has no answer before the event row exists, so the create form had
-- nothing it could call and the co-host picker only appeared on edit.
--
-- This is the same search with the only guard that makes sense beforehand:
-- the caller holds `host` or `admin`, i.e. they're someone who can create an
-- event in the first place. It exposes no more than the post-create search
-- already does — the same host/admin accounts, to the same people — just
-- without requiring an event id to point at.
--
-- Still only ever returns accounts that already hold `host` or `admin`, so
-- this can't be used to discover or escalate ordinary student accounts. The
-- caller is excluded: they become `created_by`, and the creator is never a
-- co-host of their own event.
create or replace function public.search_host_candidates_for_new_event(
  _query text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  _term text := '%' || trim(coalesce(_query, '')) || '%';
begin
  if not exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and role in ('host', 'admin')
  ) then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'user_id',    p.id,
          'full_name',  p.full_name,
          'email',      p.email,
          'avatar_url', p.avatar_url,
          'is_owner',   false
        )
        order by p.full_name
      )
      from (
        select p.*
        from public.profiles p
        where exists (
                select 1 from public.user_roles r
                where r.user_id = p.id and r.role in ('host', 'admin')
              )
          and p.id is distinct from auth.uid()
          and p.banned_at is null
          and (
            coalesce(p.full_name, '') ilike _term
            or coalesce(p.email, '') ilike _term
          )
        order by p.full_name
        limit 20
      ) p
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.search_host_candidates_for_new_event(text)
  to authenticated;
