-- Spec: group meetings "must take place within the Tel Aviv University
-- campus only." No geolocation infra exists, so this is enforced by
-- constraining location to an admin-curated list of campus locations
-- (the same `option_lists` mechanism already used for faculties, hobbies,
-- etc.) instead of accepting free text.

alter table public.option_lists
  drop constraint option_lists_list_type_check;

alter table public.option_lists
  add constraint option_lists_list_type_check
  check (list_type = any (array[
    'faculty', 'field_of_study', 'degree', 'hobby', 'interest',
    'language', 'event_category', 'benefit_category', 'campus_location'
  ]));

insert into public.option_lists (list_type, label, label_ar, label_he, sort_order, active)
values
  ('campus_location', 'Main Library', 'المكتبة الرئيسية', 'הספרייה המרכזית', 1, true),
  ('campus_location', 'Student Union Building', 'مبنى اتحاد الطلاب', 'בניין אגודת הסטודנטים', 2, true),
  ('campus_location', 'Sports Center', 'المركز الرياضي', 'המרכז הספורטיבי', 3, true),
  ('campus_location', 'Engineering Faculty', 'كلية الهندسة', 'הפקולטה להנדסה', 4, true),
  ('campus_location', 'Exact Sciences Faculty', 'كلية العلوم الدقيقة', 'הפקולטה למדעים מדויקים', 5, true),
  ('campus_location', 'Life Sciences Faculty', 'كلية علوم الحياة', 'הפקולטה למדעי החיים', 6, true),
  ('campus_location', 'Gate 4 Plaza', 'ساحة البوابة 4', 'כיכר שער 4', 7, true),
  ('campus_location', 'Smolarz Auditorium', 'قاعة سمولارز', 'אודיטוריום סמולרז', 8, true);

create or replace function public.create_group_meeting(
  _title text,
  _description text,
  _scheduled_at timestamptz,
  _location text,
  _max_participants int default 10
)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if _max_participants is null or _max_participants not between 3 and 10 then
    return jsonb_build_object('status', 'invalid_size');
  end if;

  if not exists (
    select 1 from option_lists
    where list_type = 'campus_location' and label = _location and active
  ) then
    return jsonb_build_object('status', 'invalid_location');
  end if;

  insert into group_meetings (organizer_id, title, description, scheduled_at, location, max_participants)
  values (auth.uid(), _title, _description, _scheduled_at, _location, _max_participants);
  return jsonb_build_object('status', 'ok');
end;
$function$;
