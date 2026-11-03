-- Matches has no paging. `list_match_candidates` returned only the 200 newest
-- discoverable profiles, so everyone else was missing from the list even when
-- search and filters would have included them. Return every discoverable
-- student. Body is 0087's, without `limit 200`.

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
      and public.is_discoverable_student(p.id)
    order by p.created_at desc
  ) c;
$$;

grant execute on function public.list_match_candidates() to authenticated;
