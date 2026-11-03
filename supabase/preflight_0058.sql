-- RUN THIS FIRST, BEFORE 0058, AND SAVE THE OUTPUT.
--
-- 0058 runs `drop not null` on the columns below. This records their current
-- nullability so it can be restored exactly. Without this snapshot a rollback
-- would be guesswork: re-adding `not null` to a column that was already
-- nullable imposes a constraint your schema never had.
--
-- Export the result (Download CSV) and keep it.

select
  table_name,
  column_name,
  is_nullable,
  case is_nullable
    when 'NO' then
      'alter table public.' || table_name ||
      ' alter column ' || column_name || ' set not null;'
    else
      '-- ' || table_name || '.' || column_name ||
      ' was already nullable: leave it alone on rollback'
  end as rollback_statement
from information_schema.columns
where table_schema = 'public'
  and (table_name, column_name) in (
    ('benefits','created_by'),
    ('events','approved_by'),
    ('group_meetings','approved_by'),
    ('group_meetings','organizer_id'),
    ('host_event_access','granted_by'),
    ('legal_documents','updated_by'),
    ('option_lists','created_by'),
    ('support_contacts','updated_by'),
    ('surveys','created_by'),
    ('reports','reporter_id'),
    ('reports','reported_user_id'),
    ('digital_cards','redeemed_by')
  )
order by table_name, column_name;
