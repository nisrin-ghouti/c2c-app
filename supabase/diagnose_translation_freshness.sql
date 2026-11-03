-- Does translate-content still work at all, for anything?
--
-- The admin app (c2c-admin) gained benefit AND event translation support on
-- the same day (2026-09-06, commits bc01b64 / 16656f8) and calls the function
-- identically for both. Yet 26/59 events have ar/he and 0/9 benefits do.
--
-- If events created BEFORE 2026-09-06 are translated but newer ones are not,
-- the 26 are legacy and the function is broken for everything today.
-- If events created AFTER that date are translated, the function works and is
-- simply missing `benefits` from its FIELD_GROUPS.

select 'events' as kind,
       (created_at >= timestamptz '2026-09-06') as since_feature,
       count(*)                                 as rows,
       count(title_ar)                          as has_ar,
       count(title_he)                          as has_he
from public.events
group by 1, 2

union all

select 'benefits',
       (created_at >= timestamptz '2026-09-06'),
       count(*), count(title_ar), count(title_he)
from public.benefits
group by 1, 2
order by kind, since_feature;
