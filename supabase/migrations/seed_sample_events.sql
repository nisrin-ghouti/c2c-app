-- Sample/demo data for the Events feature — covers every event "shape" the
-- app supports: single vs. program (multi-session), every approval status,
-- and a spread of visibility modes. Safe to run more than once (idempotent
-- guards on both option_lists and events).
--
-- BEFORE RUNNING: replace the email below with a real admin/host account in
-- your `profiles` table — every event needs a valid `created_by`.
-- Run in the Supabase SQL editor.

-- 1. Event categories (option_lists has NO starter rows for 'event_category'
--    out of the box — the dropdown is empty until these exist) -------------
insert into public.option_lists (list_type, label, sort_order)
select v.list_type, v.label, v.sort_order
from (values
  ('event_category', 'Workshop',      1),
  ('event_category', 'Seminar',       2),
  ('event_category', 'Social',        3),
  ('event_category', 'Sports',        4),
  ('event_category', 'Career',        5),
  ('event_category', 'Cultural',      6),
  ('event_category', 'Volunteering',  7),
  ('event_category', 'Music',         8),
  ('event_category', 'Tech',          9),
  ('event_category', 'Academic',     10)
) as v(list_type, label, sort_order)
where not exists (
  select 1 from public.option_lists o
  where o.list_type = v.list_type and o.label = v.label
);

-- 2. Host used for every seeded event ---------------------------------------
do $$
declare
  _host uuid;
begin
  select id into _host from public.profiles where email = 'jamuaf9536@gmail.com' limit 1;
  if _host is null then
    raise exception 'No profile found for that email — update the email in this script to a real host account first.';
  end if;

  -- 3. Single, approved, visible-to-everyone events, one per category ------
  insert into public.events (
    title, description, category, location, starts_at, ends_at, points, image_url,
    created_by, organizer_name, organizer_description, external_link,
    event_kind, approval_status, visibility, qr_enabled, capacity
  )
  select v.title, v.description, v.category, v.location, v.starts_at, v.ends_at, v.points, v.image_url,
         _host, v.organizer_name, v.organizer_description, v.external_link,
         'single', 'approved', 'everyone', true, v.capacity
  from (values
    (
      'Intro to Flutter Workshop', 'Hands-on workshop building your first mobile app with Flutter and Dart.',
      'Workshop', 'Engineering Building, Room 214',
      now() + interval '3 days' + interval '14 hours', now() + interval '3 days' + interval '17 hours',
      25, 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200&q=80',
      'Campus Dev Club', 'Student-run society for software and app development.', 'https://example.com/flutter-workshop', 40
    ),
    (
      'Guest Lecture: The Future of AI', 'A seminar with an industry researcher on where machine learning is headed next.',
      'Seminar', 'Main Auditorium',
      now() + interval '5 days' + interval '13 hours', now() + interval '5 days' + interval '15 hours',
      15, 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=1200&q=80',
      'Faculty of Engineering', 'Official faculty events office.', null, 200
    ),
    (
      'End of Semester Mixer', 'Casual evening social with music, snacks, and games to unwind before finals.',
      'Social', 'Student Union Rooftop',
      now() + interval '7 days' + interval '19 hours', now() + interval '7 days' + interval '22 hours',
      10, 'https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=1200&q=80',
      'Student Union', 'Your campus social committee.', null, null
    ),
    (
      'Campus 5K Fun Run', 'Timed 5K run around campus loop, open to all fitness levels. Medals for top finishers.',
      'Sports', 'Campus Track & Field',
      now() + interval '10 days' + interval '7 hours', now() + interval '10 days' + interval '9 hours',
      20, 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=1200&q=80',
      'Athletics Department', 'Organizing campus sports and wellness events.', 'https://example.com/5k-run', 150
    ),
    (
      'Spring Career Fair', 'Meet recruiters from 30+ companies hiring for internships and full-time roles.',
      'Career', 'Sports Hall',
      now() + interval '14 days' + interval '10 hours', now() + interval '14 days' + interval '16 hours',
      30, 'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=1200&q=80',
      'Career Services', 'Connecting students with employers.', 'https://example.com/career-fair', 500
    ),
    (
      'International Culture Night', 'Food, performances, and traditions from our international student community.',
      'Cultural', 'Great Hall',
      now() + interval '16 days' + interval '18 hours', now() + interval '16 days' + interval '21 hours',
      15, 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=1200&q=80',
      'International Students Association', 'Celebrating diversity on campus.', null, 300
    ),
    (
      'Beach Cleanup Volunteer Day', 'Community service morning cleaning the local beach. Transport provided.',
      'Volunteering', 'Meet at Main Gate',
      now() + interval '9 days' + interval '8 hours', now() + interval '9 days' + interval '12 hours',
      25, 'https://images.unsplash.com/photo-1618477461853-cf6ed80faba5?w=1200&q=80',
      'Green Campus Initiative', 'Student sustainability and volunteering group.', null, 60
    ),
    (
      'Open Mic & Live Music Night', 'Student musicians and bands perform. Sign up at the door to play.',
      'Music', 'Campus Cafe',
      now() + interval '4 days' + interval '20 hours', now() + interval '4 days' + interval '23 hours',
      10, 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1200&q=80',
      'Music Society', 'For students who play, sing, or just love live music.', null, 80
    ),
    (
      '24-Hour Hackathon Kickoff', 'Opening ceremony and team formation for the annual campus hackathon.',
      'Tech', 'Innovation Lab',
      now() + interval '20 days' + interval '17 hours', now() + interval '20 days' + interval '19 hours',
      35, 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=1200&q=80',
      'Campus Dev Club', 'Student-run society for software and app development.', 'https://example.com/hackathon', 120
    ),
    (
      'Undergraduate Research Symposium', 'Students present academic research posters and talks across all faculties.',
      'Academic', 'Library Conference Center',
      now() + interval '12 days' + interval '9 hours', now() + interval '12 days' + interval '13 hours',
      20, 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1200&q=80',
      'Office of Undergraduate Research', 'Supporting student research initiatives.', null, 250
    )
  ) as v(title, description, category, location, starts_at, ends_at, points, image_url,
         organizer_name, organizer_description, external_link, capacity)
  where not exists (select 1 from public.events e where e.title = v.title);

  -- 4. A multi-session "program" event (e.g. a career week) ----------------
  if not exists (select 1 from public.events where title = 'Career Week 2026') then
    declare
      _program_id uuid;
    begin
      insert into public.events (
        title, description, category, location, starts_at, ends_at, points, image_url,
        created_by, organizer_name, organizer_description,
        event_kind, approval_status, visibility, qr_enabled, capacity
      ) values (
        'Career Week 2026', 'A full week of employer talks, resume clinics, and mock interviews.',
        'Career', 'Various Campus Locations',
        now() + interval '21 days', now() + interval '25 days',
        40, 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&q=80',
        _host, 'Career Services', 'Connecting students with employers.',
        'program', 'approved', 'everyone', true, null
      )
      returning id into _program_id;

      insert into public.event_sessions (event_id, title, starts_at, ends_at, location)
      values
        (_program_id, 'Resume Clinic', now() + interval '21 days' + interval '10 hours', now() + interval '21 days' + interval '13 hours', 'Career Services Office'),
        (_program_id, 'Employer Panel: Tech Careers', now() + interval '22 days' + interval '14 hours', now() + interval '22 days' + interval '16 hours', 'Main Auditorium'),
        (_program_id, 'Mock Interview Day', now() + interval '24 days' + interval '9 hours', now() + interval '24 days' + interval '17 hours', 'Sports Hall');
    end;
  end if;

  -- 5. One event pending admin approval (to test the approval queue) -------
  insert into public.events (
    title, description, category, location, starts_at, ends_at, points, image_url,
    created_by, organizer_name, event_kind, approval_status, visibility, qr_enabled
  )
  select 'Pop-Up Board Game Night', 'Casual tabletop games night in the common room, bring your own or use ours.',
         'Social', 'Dorm Common Room', now() + interval '6 days' + interval '19 hours', now() + interval '6 days' + interval '22 hours',
         5, 'https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?w=1200&q=80',
         _host, 'Residence Hall Council', 'single', 'pending', 'everyone', true
  where not exists (select 1 from public.events where title = 'Pop-Up Board Game Night');

  -- 6. One rejected event (to test the rejection-reason display) -----------
  insert into public.events (
    title, description, category, location, starts_at, ends_at, points, image_url,
    created_by, organizer_name, event_kind, approval_status, rejection_reason, visibility, qr_enabled
  )
  select 'Late-Night Study Rave', 'Loud music study session in the library basement.',
         'Social', 'Library Basement', now() + interval '8 days' + interval '22 hours', now() + interval '9 days' + interval '2 hours',
         5, 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=1200&q=80',
         _host, 'Anonymous Student', 'single', 'rejected', 'Noise and hours conflict with library quiet-study policy.', 'everyone', true
  where not exists (select 1 from public.events where title = 'Late-Night Study Rave');

  -- 7. A private ("only me" host-only) event, useful for testing host tools -
  insert into public.events (
    title, description, category, location, starts_at, ends_at, points, image_url,
    created_by, organizer_name, event_kind, approval_status, visibility, qr_enabled, capacity
  )
  select 'Private Committee Planning Meeting', 'Internal planning session, not open to the general student body.',
         'Academic', 'Admin Building, Room 5', now() + interval '2 days' + interval '15 hours', now() + interval '2 days' + interval '16 hours',
         0, null,
         _host, 'Events Committee', 'single', 'approved', 'only_me', false, 10
  where not exists (select 1 from public.events where title = 'Private Committee Planning Meeting');
end $$;
