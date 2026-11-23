-- Keep cancelled registrations on the admin registrants list.
--
-- `cancel_event_registration` does not delete the row. It sets
-- `event_registrations.status` to `cancelled`. `register_for_event` writes
-- the same `(event_id, user_id)` row back to `registered` on conflict, so a
-- student who signs up again is registered immediately.
--
-- That second signup is not an approval request. A program acceptance row,
-- when one exists, is left untouched by both RPCs, so someone who was
-- already accepted does not go back to waiting for approval. Someone who
-- had only applied, and was never accepted, is an applicant again.
--
-- The list used to hide `cancelled` rows (`status = 'registered'` only),
-- which meant the admin console had nothing to label. `status` is additive.

create or replace function public.admin_list_event_registrants(
  _event_id uuid,
  _session_id uuid default null::uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not exists (select 1 from public.events where id = _event_id) then
    return '[]'::jsonb;
  end if;

  if not public.can_manage_event(_event_id) then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'user_id',         p.id,
        'full_name',       p.full_name,
        'email',           p.email,
        'gender',          p.gender,
        'faculty',         coalesce((p.faculties)[1], p.faculty),
        'field_of_study',  coalesce((p.fields_of_study)[1], p.field_of_study),
        'interests',       coalesce(p.interests, '{}'::text[]),
        'student_id',      p.student_id,
        'degree',          p.degree,
        'year',            p.year,
        'hobbies',         coalesce(p.hobbies, '{}'::text[]),
        'languages',       coalesce(p.languages, '{}'::text[]),
        'bio',             p.bio,
        'registered_at',   r.registered_at,
        'attended_at',     a.scanned_at,
        'status',          r.status
      ) order by (r.status = 'cancelled'), r.registered_at)
      from public.event_registrations r
      join public.profiles p on p.id = r.user_id
      left join public.event_attendance a
        on a.event_id = r.event_id
        and a.user_id  = r.user_id
        and coalesce(a.session_id, '00000000-0000-0000-0000-000000000000'::uuid)
          = coalesce(_session_id, '00000000-0000-0000-0000-000000000000'::uuid)
      where r.event_id = _event_id
        and r.session_id is null
        and r.status in ('registered', 'cancelled')
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.admin_list_event_registrants(uuid, uuid) from public;
grant execute on function public.admin_list_event_registrants(uuid, uuid) to authenticated;
