-- Restaurant administration workflows.  These operations are deliberately
-- tenant-scoped and actor-derived so UI controls are never the permission boundary.

create table public.coupons (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  discount_id uuid not null references public.discounts(id) on delete restrict,
  code text not null,
  starts_at timestamptz,
  ends_at timestamptz,
  redemption_limit integer check (redemption_limit is null or redemption_limit > 0),
  redemption_count integer not null default 0 check (redemption_count >= 0),
  minimum_order_amount integer not null default 0 check (minimum_order_amount >= 0),
  is_active boolean not null default true,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (restaurant_id, code),
  check (ends_at is null or starts_at is null or ends_at > starts_at),
  check (redemption_limit is null or redemption_count <= redemption_limit)
);

create table public.coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  coupon_id uuid not null references public.coupons(id) on delete restrict,
  order_id uuid not null references public.orders(id) on delete restrict,
  redeemed_by uuid not null references auth.users(id) on delete restrict,
  redeemed_at timestamptz not null default now(),
  unique (coupon_id, order_id)
);

create table public.restaurant_settings (
  restaurant_id uuid primary key references public.restaurants(id) on delete cascade,
  service_charge_basis_points integer not null default 0 check (service_charge_basis_points between 0 and 10000),
  invoice_prefix text not null default 'INV' check (char_length(invoice_prefix) between 1 and 20),
  receipt_footer text,
  auto_accept_kitchen_orders boolean not null default true,
  require_table_guest_count boolean not null default true,
  allow_order_holds boolean not null default true,
  sound_notifications boolean not null default true,
  compact_table_density boolean not null default false,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.branches
  add column if not exists opens_at time,
  add column if not exists closes_at time,
  add column if not exists timezone text,
  add constraint branches_operating_hours_check check (opens_at is null or closes_at is null or opens_at <> closes_at);

alter table public.coupons enable row level security;
alter table public.coupon_redemptions enable row level security;
alter table public.restaurant_settings enable row level security;

create policy "coupons: members read" on public.coupons for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "coupons: managers insert" on public.coupons for insert to authenticated with check (created_by = auth.uid() and public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "coupons: managers update" on public.coupons for update to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "coupons: managers delete" on public.coupons for delete to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "coupon redemptions: members read" on public.coupon_redemptions for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "settings: members read" on public.restaurant_settings for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "settings: managers write" on public.restaurant_settings for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])) with check (updated_by = auth.uid() and public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));

create or replace function public.record_inventory_movement(
  p_inventory_item_id uuid, p_movement_type text, p_quantity_delta numeric,
  p_unit_cost_amount integer default null, p_note text default null
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_actor uuid := auth.uid(); v_item public.inventory_items%rowtype; v_id uuid;
begin
  if v_actor is null or p_movement_type not in ('purchase', 'waste', 'adjustment', 'sale', 'return') or p_quantity_delta = 0 then
    raise exception 'Invalid stock movement' using errcode = '22023';
  end if;
  select * into v_item from public.inventory_items where id = p_inventory_item_id for update;
  if not found or not public.has_restaurant_role(v_item.restaurant_id, array['owner', 'manager']::public.app_role[]) then
    raise exception 'Not permitted to adjust inventory' using errcode = '42501';
  end if;
  if p_movement_type in ('waste', 'sale') and p_quantity_delta >= 0 then raise exception 'Waste and sales must reduce stock' using errcode = '22023'; end if;
  if p_movement_type in ('purchase', 'return') and p_quantity_delta <= 0 then raise exception 'Purchases and returns must increase stock' using errcode = '22023'; end if;
  insert into public.inventory_movements (restaurant_id, inventory_item_id, movement_type, quantity_delta, unit_cost_amount, note, recorded_by)
  values (v_item.restaurant_id, v_item.id, p_movement_type, p_quantity_delta, p_unit_cost_amount, nullif(trim(p_note), ''), v_actor) returning id into v_id;
  update public.inventory_items set current_quantity = current_quantity + p_quantity_delta, updated_at = now() where id = v_item.id;
  return v_id;
end; $$;

create or replace function public.redeem_coupon(p_coupon_code text, p_order_id uuid)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_actor uuid := auth.uid(); v_coupon public.coupons%rowtype; v_order public.orders%rowtype; v_id uuid;
begin
  if v_actor is null then raise exception 'Authentication is required' using errcode = '28000'; end if;
  select * into v_order from public.orders where id = p_order_id for update;
  select * into v_coupon from public.coupons where restaurant_id = v_order.restaurant_id and code = upper(trim(p_coupon_code)) for update;
  if not found or not v_coupon.is_active or (v_coupon.starts_at is not null and v_coupon.starts_at > now()) or (v_coupon.ends_at is not null and v_coupon.ends_at <= now()) or (v_coupon.redemption_limit is not null and v_coupon.redemption_count >= v_coupon.redemption_limit) or v_order.subtotal_amount < v_coupon.minimum_order_amount then
    raise exception 'Coupon is not eligible for this order' using errcode = '22023';
  end if;
  if not public.has_restaurant_role(v_order.restaurant_id, array['owner', 'manager', 'cashier']::public.app_role[]) then raise exception 'Not permitted to redeem coupons' using errcode = '42501'; end if;
  insert into public.coupon_redemptions (restaurant_id, coupon_id, order_id, redeemed_by) values (v_order.restaurant_id, v_coupon.id, v_order.id, v_actor) returning id into v_id;
  update public.coupons set redemption_count = redemption_count + 1, updated_at = now() where id = v_coupon.id;
  return v_id;
end; $$;

create or replace function public.update_staff_membership(p_membership_id uuid, p_role public.app_role default null, p_is_active boolean default null)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_actor uuid := auth.uid(); v_actor_role public.app_role; v_target public.restaurant_memberships%rowtype;
begin
  select * into v_target from public.restaurant_memberships where id = p_membership_id for update;
  if not found then raise exception 'Staff membership was not found' using errcode = '22023'; end if;
  select role into v_actor_role from public.restaurant_memberships where restaurant_id = v_target.restaurant_id and user_id = v_actor and is_active;
  if v_actor_role is null or v_actor_role not in ('owner', 'manager') then raise exception 'Not permitted to manage staff' using errcode = '42501'; end if;
  if v_target.role = 'owner' or (v_actor_role = 'manager' and (coalesce(p_role, v_target.role) in ('owner', 'manager'))) then raise exception 'Only an owner can make this role change' using errcode = '42501'; end if;
  update public.restaurant_memberships set role = coalesce(p_role, role), is_active = coalesce(p_is_active, is_active), updated_at = now() where id = v_target.id;
end; $$;

revoke all on function public.record_inventory_movement(uuid, text, numeric, integer, text) from public;
revoke all on function public.redeem_coupon(text, uuid) from public;
revoke all on function public.update_staff_membership(uuid, public.app_role, boolean) from public;
grant execute on function public.record_inventory_movement(uuid, text, numeric, integer, text), public.redeem_coupon(text, uuid), public.update_staff_membership(uuid, public.app_role, boolean) to authenticated;
