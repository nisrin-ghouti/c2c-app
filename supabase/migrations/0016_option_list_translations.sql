-- Translations for admin-curated option lists (categories, faculties,
-- hobbies, interests, languages, degrees, fields of study).
--
-- These labels can't live in the .arb files: admins add and delete them at
-- runtime, so the app can't know them at build time. They belong next to the
-- option they translate.
--
-- `label` stays the canonical value. Events and benefits store their category
-- as that English text, so changing `label` would orphan every row already
-- pointing at it — the translations are additive columns instead.

alter table public.option_lists
  add column if not exists label_ar text,
  add column if not exists label_he text;

-- Seed translations for everything shipped in 0002, plus the category names an
-- admin is most likely to have created. Only fills blanks (`is null`), so an
-- admin's own wording is never overwritten by a re-run.
update public.option_lists o
set label_ar = coalesce(o.label_ar, t.ar),
    label_he = coalesce(o.label_he, t.he)
from (values
  -- Fields of study
  ('Computer Science',        'علوم الحاسوب',        'מדעי המחשב'),
  ('Business Administration', 'إدارة الأعمال',        'מנהל עסקים'),
  ('Psychology',              'علم النفس',            'פסיכולוגיה'),
  ('Law',                     'القانون',              'משפטים'),
  ('Medicine',                'الطب',                 'רפואה'),
  ('Engineering',             'الهندسة',              'הנדסה'),
  ('Education',               'التربية',              'חינוך'),

  -- Faculties
  ('Humanities',              'العلوم الإنسانية',     'מדעי הרוח'),
  ('Social Sciences',         'العلوم الاجتماعية',    'מדעי החברה'),
  ('Natural Sciences',        'العلوم الطبيعية',      'מדעי הטבע'),
  ('Business',                'إدارة الأعمال',        'עסקים'),

  -- Interests
  ('Technology',              'التكنولوجيا',          'טכנולוגיה'),
  ('Music',                   'الموسيقى',             'מוזיקה'),
  ('Sports',                  'الرياضة',              'ספורט'),
  ('Art',                     'الفن',                 'אמנות'),
  ('Volunteering',            'التطوع',               'התנדבות'),
  ('Gaming',                  'الألعاب',              'גיימינג'),
  ('Travel',                  'السفر',                'טיולים'),
  ('Reading',                 'القراءة',              'קריאה'),

  -- Hobbies
  ('Photography',             'التصوير',              'צילום'),
  ('Cooking',                 'الطبخ',                'בישול'),
  ('Hiking',                  'المشي في الطبيعة',     'טיולים רגליים'),
  ('Painting',                'الرسم',                'ציור'),
  ('Running',                 'الجري',                'ריצה'),
  ('Chess',                   'الشطرنج',              'שחמט'),
  ('Dancing',                 'الرقص',                'ריקוד'),

  -- Languages
  ('Hebrew',                  'العبرية',              'עברית'),
  ('Arabic',                  'العربية',              'ערבית'),
  ('English',                 'الإنجليزية',           'אנגלית'),
  ('Russian',                 'الروسية',              'רוסית'),
  ('French',                  'الفرنسية',             'צרפתית'),
  ('Spanish',                 'الإسبانية',            'ספרדית'),

  -- Degrees
  ('Bachelor''s',             'بكالوريوس',            'תואר ראשון'),
  ('Master''s',               'ماجستير',              'תואר שני'),
  ('PhD',                     'دكتوراه',              'דוקטורט'),

  -- Common event / benefit categories
  ('Food',                    'الطعام',               'אוכל'),
  ('Coffee',                  'القهوة',               'קפה'),
  ('Restaurant',              'مطعم',                 'מסעדה'),
  ('Fashion',                 'الأزياء',              'אופנה'),
  ('Fitness',                 'اللياقة البدنية',      'כושר'),
  ('Health',                  'الصحة',                'בריאות'),
  ('Beauty',                  'التجميل',              'יופי'),
  ('Entertainment',           'الترفيه',              'בידור'),
  ('Culture',                 'الثقافة',              'תרבות'),
  ('Workshop',                'ورشة عمل',             'סדנה'),
  ('Lecture',                 'محاضرة',               'הרצאה'),
  ('Party',                   'حفلة',                 'מסיבה'),
  ('Social',                  'اجتماعي',              'חברתי'),
  ('Academic',                'أكاديمي',              'אקדמי'),
  ('Career',                  'المسار المهني',        'קריירה'),
  ('Volunteer',               'تطوع',                 'התנדבות'),
  ('Trip',                    'رحلة',                 'טיול'),
  ('Sport',                   'رياضة',                'ספורט'),
  ('Books',                   'الكتب',                'ספרים'),
  ('Technology',              'التكنولوجيا',          'טכנולוגיה'),
  ('Transport',               'المواصلات',            'תחבורה'),
  ('Other',                   'أخرى',                 'אחר')
) as t(label, ar, he)
where o.label = t.label
  and (o.label_ar is null or o.label_he is null);
