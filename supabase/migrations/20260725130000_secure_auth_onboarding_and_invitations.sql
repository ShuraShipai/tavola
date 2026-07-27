-- Secure authentication-adjacent workflows.  All actor identity is derived
-- from auth.uid(); client supplied user and restaurant ownership is ignored.

alter table public.profiles
  add column if not exists phone text,
  add column if not exists terms_accepted_at timestamptz;

alter table public.restaurant_memberships
  add column if not exists staff_pin_hash text,
  add column if not exists staff_pin_failed_attempts integer not null default 0,
  add column if not exists staff_pin_locked_until timestamptz;

create or replace function public.set_staff_pin(
  p_membership_id uuid,
  p_pin text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_target public.restaurant_memberships%rowtype;
begin
  if v_actor is null or p_pin !~ '^[0-9]{4}$' then
    raise exception 'A signed-in user and four-digit PIN are required' using errcode = '22023';
  end if;
  select * into v_target from public.restaurant_memberships where id = p_membership_id and is_active for update;
  if not found then raise exception 'Staff membership was not found' using errcode = '22023'; end if;
  if v_target.user_id <> v_actor and not public.has_restaurant_role(v_target.restaurant_id, array['owner', 'manager']::public.app_role[]) then
    raise exception 'You are not permitted to set this staff PIN' using errcode = '42501';
  end if;
  update public.restaurant_memberships
  set staff_pin_hash = crypt(p_pin, gen_salt('bf', 10)), staff_pin_failed_attempts = 0, staff_pin_locked_until = null
  where id = p_membership_id;
end;
$$;

create or replace function public.verify_staff_pin(p_restaurant_id uuid, p_pin text)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_membership public.restaurant_memberships%rowtype;
  v_valid boolean := false;
begin
  if v_actor is null or p_pin !~ '^[0-9]{4}$' then return false; end if;
  select * into v_membership
  from public.restaurant_memberships
  where restaurant_id = p_restaurant_id and user_id = v_actor and is_active
  for update;
  if not found or (v_membership.staff_pin_locked_until is not null and v_membership.staff_pin_locked_until > now()) then return false; end if;
  v_valid := v_membership.staff_pin_hash is not null and v_membership.staff_pin_hash = crypt(p_pin, v_membership.staff_pin_hash);
  if v_valid then
    update public.restaurant_memberships set staff_pin_failed_attempts = 0, staff_pin_locked_until = null where id = v_membership.id;
  else
    update public.restaurant_memberships
    set staff_pin_failed_attempts = staff_pin_failed_attempts + 1,
        staff_pin_locked_until = case when staff_pin_failed_attempts + 1 >= 5 then now() + interval '15 minutes' else staff_pin_locked_until end
    where id = v_membership.id;
  end if;
  return v_valid;
end;
$$;

create or replace function public.new_restaurant_code()
returns text
language plpgsql
volatile
set search_path = public, pg_temp
as $$
begin
  return 'TAV-' || upper(substr(encode(gen_random_bytes(5), 'hex'), 1, 8));
end;
$$;

alter table public.restaurants
  add column if not exists restaurant_code text,
  add column if not exists restaurant_type text;

update public.restaurants
set restaurant_code = public.new_restaurant_code()
where restaurant_code is null;

alter table public.restaurants
  alter column restaurant_code set default public.new_restaurant_code(),
  alter column restaurant_code set not null;

create unique index if not exists restaurants_restaurant_code_key
  on public.restaurants (restaurant_code);

create table if not exists public.restaurant_invitations (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  invited_email text not null,
  invite_code_hash text not null,
  role public.app_role not null default 'waiter',
  expires_at timestamptz not null,
  revoked_at timestamptz,
  redeemed_at timestamptz,
  redeemed_by uuid references auth.users(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  check (expires_at > created_at),
  check (role <> 'owner')
);

create index if not exists restaurant_invitations_active_lookup_idx
  on public.restaurant_invitations (restaurant_id, invited_email, expires_at)
  where redeemed_at is null and revoked_at is null;

alter table public.restaurant_invitations enable row level security;

create policy "invitations: managers read" on public.restaurant_invitations
  for select to authenticated
  using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));

create policy "invitations: managers create" on public.restaurant_invitations
  for insert to authenticated
  with check (
    created_by = auth.uid()
    and public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])
  );

create policy "invitations: managers revoke" on public.restaurant_invitations
  for update to authenticated
  using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]))
  with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));

create or replace function public.complete_restaurant_onboarding(
  p_name text,
  p_restaurant_type text default null,
  p_phone text default null,
  p_timezone text default 'Asia/Kolkata'
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor_id uuid := auth.uid();
  v_restaurant_id uuid;
begin
  if v_actor_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if nullif(trim(p_name), '') is null then
    raise exception 'Restaurant name is required' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.restaurant_memberships
    where user_id = v_actor_id and is_active
  ) then
    raise exception 'A restaurant workspace already exists for this account' using errcode = '23505';
  end if;

  insert into public.restaurants (name, restaurant_type, timezone, owner_id)
  values (trim(p_name), nullif(trim(p_restaurant_type), ''), coalesce(nullif(trim(p_timezone), ''), 'Asia/Kolkata'), v_actor_id)
  returning id into v_restaurant_id;

  update public.profiles
  set phone = nullif(trim(p_phone), ''), terms_accepted_at = coalesce(terms_accepted_at, now())
  where id = v_actor_id;

  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data)
  values (
    v_restaurant_id,
    v_actor_id,
    'restaurant',
    v_restaurant_id,
    'onboarded',
    jsonb_build_object('restaurant_type', nullif(trim(p_restaurant_type), ''))
  );
  return v_restaurant_id;
end;
$$;

create or replace function public.redeem_restaurant_invitation(
  p_restaurant_code text,
  p_invite_code text
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor_id uuid := auth.uid();
  v_email text;
  v_invitation public.restaurant_invitations%rowtype;
begin
  if v_actor_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  select lower(email) into v_email from auth.users where id = v_actor_id;
  select invitation.* into v_invitation
  from public.restaurant_invitations invitation
  join public.restaurants restaurant on restaurant.id = invitation.restaurant_id
  where restaurant.restaurant_code = upper(trim(p_restaurant_code))
    and invitation.invited_email = v_email
    and invitation.redeemed_at is null
    and invitation.revoked_at is null
    and invitation.expires_at > now()
    and invitation.invite_code_hash = crypt(p_invite_code, invitation.invite_code_hash)
  for update of invitation;

  if not found then
    raise exception 'The restaurant ID or invite code is invalid or expired' using errcode = '22023';
  end if;

  insert into public.restaurant_memberships (restaurant_id, user_id, role)
  values (v_invitation.restaurant_id, v_actor_id, v_invitation.role)
  on conflict (restaurant_id, user_id) do update set is_active = true, role = excluded.role;

  update public.restaurant_invitations
  set redeemed_at = now(), redeemed_by = v_actor_id
  where id = v_invitation.id;

  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data)
  values (
    v_invitation.restaurant_id,
    v_actor_id,
    'restaurant_invitation',
    v_invitation.id,
    'redeemed',
    jsonb_build_object('role', v_invitation.role)
  );
  return v_invitation.restaurant_id;
end;
$$;

revoke all on function public.complete_restaurant_onboarding(text, text, text, text) from public;
grant execute on function public.complete_restaurant_onboarding(text, text, text, text) to authenticated;
revoke all on function public.redeem_restaurant_invitation(text, text) from public;
grant execute on function public.redeem_restaurant_invitation(text, text) to authenticated;
revoke all on function public.set_staff_pin(uuid, text) from public;
grant execute on function public.set_staff_pin(uuid, text) to authenticated;
revoke all on function public.verify_staff_pin(uuid, text) from public;
grant execute on function public.verify_staff_pin(uuid, text) to authenticated;
