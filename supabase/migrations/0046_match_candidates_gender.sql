-- Exposes `gender` on match candidates so the Matches screen can offer a
-- Female/Male/Prefer not to say/All filter, matching the existing profile
-- gender values (see 0009_add_profile_gender.sql, 0040_gender_remove_other.sql).

create or replace function public.list_match_candidates()
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select coalesce(jsonb_agg(row_to_json(c) order by c.created_at desc), '[]'::jsonb)
  from (
    select
      p.id, p.full_name, p.faculty, p.field_of_study, p.faculties, p.fields_of_study,
      p.degree, p.year, p.bio, p.avatar_hue, p.avatar_url, p.hobbies, p.interests,
      p.languages, p.gender, p.created_at
    from public.profiles p
    where p.id <> auth.uid()
      and p.deleted_at is null
      and public.is_student_eligible(p.id)
    order by p.created_at desc
    limit 200
  ) c;
$$;
