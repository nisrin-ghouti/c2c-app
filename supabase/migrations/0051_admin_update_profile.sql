-- The admin panel's "Edit Profile" dialog (Users -> User Details) has always
-- called `admin_update_profile`, but the function was never actually
-- created — every save attempt failed client-side with a PostgREST 404
-- ("Could not find the function ... in the schema cache"). Mirrors the
-- other admin_* profile-adjacent RPCs (security definer, admin-only,
-- 'ok'/'forbidden'/'not_found' status shape) since a plain client-side
-- `.update()` on another user's `profiles` row is silently dropped by RLS
-- rather than erroring.
create or replace function public.admin_update_profile(
  _user_id uuid,
  _full_name text,
  _gender text default null,
  _student_id text default null,
  _faculty text default null,
  _year int default null,
  _degree text default null,
  _field_of_study text default null,
  _bio text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not exists (select 1 from public.user_roles where user_id = auth.uid() and role = 'admin') then
    return jsonb_build_object('status', 'forbidden');
  end if;

  if not exists (select 1 from public.profiles where id = _user_id) then
    return jsonb_build_object('status', 'not_found');
  end if;

  update public.profiles set
    full_name = coalesce(nullif(_full_name, ''), full_name),
    gender = nullif(_gender, ''),
    student_id = nullif(_student_id, ''),
    faculty = nullif(_faculty, ''),
    year = _year,
    degree = nullif(_degree, ''),
    field_of_study = nullif(_field_of_study, ''),
    bio = nullif(_bio, '')
  where id = _user_id;

  return jsonb_build_object('status', 'ok');
end;
$$;

grant execute on function public.admin_update_profile(uuid, text, text, text, text, int, text, text, text) to authenticated;
