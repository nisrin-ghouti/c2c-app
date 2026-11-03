-- Event visibility can now be narrowed by degree type as well as faculty.
--
-- `event_visibility_targets` already stores (target_type, target_value) rows,
-- so this needs no schema change at all: a degree restriction is a row with
-- `target_type = 'degree'` and the degree label as its value, exactly as a
-- faculty restriction is a `'faculty'` row today.
--
-- What changes is how `event_is_visible_to` (0069) reads them:
--
--   faculty rows only  -> must match faculty
--   degree rows only   -> must match degree
--   both               -> must match BOTH (AND)
--   neither            -> unrestricted
--
-- The AND is the part worth being careful about. Reading the two sets
-- independently and requiring each present set to match is what produces it;
-- a single `exists` over all target rows would have produced OR, and an event
-- for "Master's students in Engineering" would have been visible to every
-- Master's student on campus.
--
-- Backward compatible by construction. An event saved before this migration
-- has only faculty rows, so the degree branch finds nothing and skips, and the
-- event behaves exactly as it did. Nothing is migrated or rewritten.
--
-- Degree values are the labels from the `degree` option list (0002 seeds
-- Bachelor's / Master's / PhD), matched against `profiles.degree` — the same
-- column the profile form writes, so no mapping table is involved.
--
-- Depends on 0069.

create or replace function public.event_is_visible_to(
  _event_id uuid,
  _user_id  uuid default auth.uid()
)
returns boolean
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  _visibility      text;
  _has_faculty     boolean;
  _has_degree      boolean;
  _faculty_ok      boolean;
  _degree_ok       boolean;
begin
  select e.visibility into _visibility
  from public.events e
  where e.id = _event_id;

  -- No such event: let the other policies answer, don't invent a denial.
  if not found then
    return true;
  end if;

  -- Anyone who runs the event always sees it — creator, co-host, group
  -- manager, or any admin. This is also what makes 'only_me' work.
  if _user_id is not null and public.can_manage_event(_event_id, _user_id) then
    return true;
  end if;

  case coalesce(_visibility, 'everyone')

    when 'only_me' then
      return false;

    when 'specific_faculties' then
      if _user_id is null then
        return false;
      end if;

      select
        exists (
          select 1 from public.event_visibility_targets t
          where t.event_id = _event_id and t.target_type = 'faculty'
        ),
        exists (
          select 1 from public.event_visibility_targets t
          where t.event_id = _event_id and t.target_type = 'degree'
        )
      into _has_faculty, _has_degree;

      -- Restricted in name only — no targets were ever saved. Treat as
      -- unrestricted rather than silently burying the event from everyone,
      -- including its intended audience.
      if not _has_faculty and not _has_degree then
        return true;
      end if;

      _faculty_ok := not _has_faculty or exists (
        select 1
        from public.profiles p
        join public.event_visibility_targets t
          on t.event_id = _event_id
         and t.target_type = 'faculty'
         and (
           -- `faculties` is the current multi-value column (0001); `faculty`
           -- is the legacy single-value one, still populated. Match either.
           t.target_value = any (coalesce(p.faculties, '{}'::text[]))
           or t.target_value = p.faculty
         )
        where p.id = _user_id
      );

      _degree_ok := not _has_degree or exists (
        select 1
        from public.profiles p
        join public.event_visibility_targets t
          on t.event_id = _event_id
         and t.target_type = 'degree'
         and t.target_value = p.degree
        where p.id = _user_id
      );

      -- AND, not OR. Each filter that was actually set must be satisfied;
      -- a filter that was not set imposes nothing.
      return _faculty_ok and _degree_ok;

    else
      -- 'everyone', 'specific_groups' (retired — see 0069), and anything
      -- unrecognised.
      return true;

  end case;

  -- Unreachable; present so an RLS predicate can never fall off the end.
  return true;
end;
$$;

revoke all on function public.event_is_visible_to(uuid, uuid) from public;
grant execute on function public.event_is_visible_to(uuid, uuid) to authenticated, anon;

-- Degree lookups now join the targets table the same way faculty ones do.
create index if not exists event_visibility_targets_type_value_idx
  on public.event_visibility_targets (event_id, target_type, target_value);

do $$
declare
  _f int;
  _d int;
begin
  select count(*) into _f from public.event_visibility_targets where target_type = 'faculty';
  select count(*) into _d from public.event_visibility_targets where target_type = 'degree';
  raise notice 'Visibility targets — faculty: %, degree: %', _f, _d;

  if not exists (select 1 from public.option_lists where list_type = 'degree' and active) then
    raise notice 'No active degree options: the picker will be empty until some exist in Possible Lists.';
  end if;
end $$;
