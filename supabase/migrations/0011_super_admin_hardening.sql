-- Super Administrator protection.
--
-- Spec: "The Super Administrator account cannot be deleted, cannot have its
-- administrator privileges removed, and its role cannot be changed, even if
-- additional administrators are added to the system."
-- Super Administrator is: NisrinGhouti@mail.tau.ac.il
--
-- The app already dims these actions in the admin UI, but that's client-side
-- only — anyone with the anon key could call the API directly. These triggers
-- enforce it in the database, which is the only place it actually holds.
--
-- Idempotent: safe to re-run. Requires the account to exist in auth.users.

-- 1. Designate the super admin ---------------------------------------------
update public.profiles p
set is_super_admin = true
from auth.users u
where u.id = p.id
  and lower(u.email) = lower('NisrinGhouti@mail.tau.ac.il');

-- The super admin is also a Student and an Admin (spec: both permissions).
insert into public.user_roles (user_id, role)
select u.id, r.role
from auth.users u
cross join (values ('admin'::app_role), ('student'::app_role)) as r(role)
where lower(u.email) = lower('NisrinGhouti@mail.tau.ac.il')
  and not exists (
    select 1 from public.user_roles x
    where x.user_id = u.id and x.role = r.role
  );

-- 2. Can't remove/change the super admin's roles ---------------------------
create or replace function public.protect_super_admin_roles()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target uuid := coalesce(old.user_id, new.user_id);
begin
  if exists (select 1 from public.profiles p
             where p.id = target and coalesce(p.is_super_admin, false)) then
    -- Deleting the admin role, or changing which user/role the row points at,
    -- would strip the super admin's privileges.
    if tg_op = 'DELETE' and old.role = 'admin'::app_role then
      raise exception 'The super administrator''s admin role cannot be removed';
    end if;
    if tg_op = 'UPDATE' and old.role = 'admin'::app_role
       and (new.role is distinct from old.role or new.user_id is distinct from old.user_id) then
      raise exception 'The super administrator''s role cannot be changed';
    end if;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_protect_super_admin_roles on public.user_roles;
create trigger trg_protect_super_admin_roles
  before update or delete on public.user_roles
  for each row execute function public.protect_super_admin_roles();

-- 3. Can't ban, delete, or de-super the super admin's profile --------------
create or replace function public.protect_super_admin_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    if coalesce(old.is_super_admin, false) then
      raise exception 'The super administrator account cannot be deleted';
    end if;
    return old;
  end if;

  if coalesce(old.is_super_admin, false) then
    if coalesce(new.is_super_admin, false) = false then
      raise exception 'The super administrator flag cannot be removed';
    end if;
    if new.banned_at is not null then
      raise exception 'The super administrator cannot be banned';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_protect_super_admin_profile on public.profiles;
create trigger trg_protect_super_admin_profile
  before update or delete on public.profiles
  for each row execute function public.protect_super_admin_profile();

-- Verify:
--   select u.email, p.is_super_admin,
--          array_agg(r.role) as roles
--   from auth.users u
--   join public.profiles p on p.id = u.id
--   left join public.user_roles r on r.user_id = u.id
--   where lower(u.email) = lower('NisrinGhouti@mail.tau.ac.il')
--   group by u.email, p.is_super_admin;
