-- Tavola initial multi-tenant restaurant POS schema.
-- All monetary values use the smallest currency unit (for example, paise/cents).

create extension if not exists pgcrypto;

do $$ begin
  create type public.app_role as enum ('owner', 'manager', 'cashier', 'waiter', 'kitchen');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.order_status as enum (
    'draft', 'open', 'sent_to_kitchen', 'preparing', 'ready', 'served', 'billed', 'paid', 'cancelled'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.payment_status as enum ('completed', 'refunded', 'voided');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.reservation_status as enum ('pending', 'confirmed', 'seated', 'completed', 'cancelled', 'no_show');
exception when duplicate_object then null; end $$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 1 and 120),
  currency_code text not null default 'INR' check (currency_code ~ '^[A-Z]{3}$'),
  timezone text not null default 'Asia/Kolkata',
  owner_id uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.restaurant_memberships (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.app_role not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (restaurant_id, user_id)
);

create index restaurant_memberships_user_restaurant_idx
  on public.restaurant_memberships (user_id, restaurant_id) where is_active;

create or replace function public.is_restaurant_member(p_restaurant_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.restaurant_memberships
    where restaurant_id = p_restaurant_id and user_id = auth.uid() and is_active
  );
$$;

create or replace function public.has_restaurant_role(
  p_restaurant_id uuid,
  p_roles public.app_role[]
)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.restaurant_memberships
    where restaurant_id = p_restaurant_id
      and user_id = auth.uid()
      and is_active
      and role = any(p_roles)
  );
$$;

create table public.branches (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 120),
  address text,
  phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (restaurant_id, name)
);

create table public.dining_tables (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  label text not null,
  capacity integer not null default 2 check (capacity > 0 and capacity <= 100),
  status text not null default 'available' check (status in ('available', 'occupied', 'reserved', 'unavailable')),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (branch_id, label)
);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  full_name text not null,
  phone text,
  email text,
  notes text,
  visit_count integer not null default 0 check (visit_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique nulls not distinct (restaurant_id, phone)
);

create table public.menu_categories (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (restaurant_id, name)
);

create table public.menu_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  category_id uuid references public.menu_categories(id) on delete set null,
  name text not null,
  description text,
  sku text,
  price_amount integer not null check (price_amount >= 0),
  tax_rate_basis_points integer not null default 0 check (tax_rate_basis_points between 0 and 10000),
  image_path text,
  is_available boolean not null default true,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique nulls not distinct (restaurant_id, sku)
);

create table public.tax_rules (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  rate_basis_points integer not null check (rate_basis_points between 0 and 10000),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (restaurant_id, name)
);

create table public.discounts (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  discount_type text not null check (discount_type in ('percentage', 'fixed_amount')),
  value integer not null check (value >= 0),
  max_discount_amount integer check (max_discount_amount is null or max_discount_amount >= 0),
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at),
  check (discount_type <> 'percentage' or value <= 10000),
  unique (restaurant_id, name)
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  order_number bigint not null,
  table_id uuid references public.dining_tables(id) on delete set null,
  customer_id uuid references public.customers(id) on delete set null,
  status public.order_status not null default 'draft',
  order_type text not null default 'dine_in' check (order_type in ('dine_in', 'takeaway', 'delivery')),
  notes text,
  subtotal_amount integer not null default 0 check (subtotal_amount >= 0),
  discount_amount integer not null default 0 check (discount_amount >= 0),
  tax_amount integer not null default 0 check (tax_amount >= 0),
  service_charge_amount integer not null default 0 check (service_charge_amount >= 0),
  total_amount integer not null default 0 check (total_amount >= 0),
  created_by uuid not null references auth.users(id) on delete restrict,
  opened_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (restaurant_id, order_number),
  check (total_amount = subtotal_amount - discount_amount + tax_amount + service_charge_amount)
);

create index orders_restaurant_status_idx on public.orders (restaurant_id, status, created_at desc);
create index orders_branch_created_idx on public.orders (branch_id, created_at desc);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  order_id uuid not null references public.orders(id) on delete cascade,
  menu_item_id uuid references public.menu_items(id) on delete set null,
  item_name text not null,
  sku_snapshot text,
  unit_price_amount integer not null check (unit_price_amount >= 0),
  quantity numeric(12,3) not null check (quantity > 0),
  discount_amount integer not null default 0 check (discount_amount >= 0),
  tax_amount integer not null default 0 check (tax_amount >= 0),
  line_total_amount integer not null check (line_total_amount >= 0),
  modifiers jsonb not null default '[]'::jsonb check (jsonb_typeof(modifiers) = 'array'),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index order_items_order_idx on public.order_items (order_id);

create table public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  order_id uuid not null references public.orders(id) on delete cascade,
  from_status public.order_status,
  to_status public.order_status not null,
  changed_by uuid references auth.users(id) on delete set null,
  changed_at timestamptz not null default now(),
  note text
);

create table public.kitchen_tickets (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  order_id uuid not null references public.orders(id) on delete cascade,
  status text not null default 'queued' check (status in ('queued', 'preparing', 'ready', 'served', 'cancelled')),
  priority integer not null default 0 check (priority between 0 and 3),
  started_at timestamptz,
  ready_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.kitchen_ticket_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  kitchen_ticket_id uuid not null references public.kitchen_tickets(id) on delete cascade,
  order_item_id uuid not null references public.order_items(id) on delete cascade,
  status text not null default 'queued' check (status in ('queued', 'preparing', 'ready', 'served', 'cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (kitchen_ticket_id, order_item_id)
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  order_id uuid not null references public.orders(id) on delete restrict,
  payment_method text not null check (payment_method in ('cash', 'card', 'upi', 'wallet', 'bank_transfer', 'other')),
  amount integer not null check (amount > 0),
  tip_amount integer not null default 0 check (tip_amount >= 0),
  status public.payment_status not null default 'completed',
  external_reference text,
  received_by uuid not null references auth.users(id) on delete restrict,
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index payments_order_idx on public.payments (order_id, paid_at desc);

create table public.payment_refunds (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  payment_id uuid not null references public.payments(id) on delete restrict,
  amount integer not null check (amount > 0),
  reason text not null,
  refunded_by uuid not null references auth.users(id) on delete restrict,
  refunded_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.shifts (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete restrict,
  opening_cash_amount integer not null default 0 check (opening_cash_amount >= 0),
  closing_cash_amount integer check (closing_cash_amount is null or closing_cash_amount >= 0),
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (closed_at is null or closed_at >= opened_at)
);

create table public.cash_drawer_movements (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  shift_id uuid not null references public.shifts(id) on delete restrict,
  movement_type text not null check (movement_type in ('cash_in', 'cash_out', 'adjustment')),
  amount integer not null check (amount > 0),
  reason text not null,
  recorded_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.reservations (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  table_id uuid references public.dining_tables(id) on delete set null,
  guest_name text not null,
  guest_phone text,
  party_size integer not null check (party_size > 0 and party_size <= 100),
  reserved_for timestamptz not null,
  duration_minutes integer not null default 90 check (duration_minutes between 15 and 720),
  status public.reservation_status not null default 'pending',
  notes text,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index reservations_branch_time_idx on public.reservations (branch_id, reserved_for);

create table public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete cascade,
  name text not null,
  sku text,
  unit text not null default 'unit',
  current_quantity numeric(14,3) not null default 0,
  reorder_level numeric(14,3) not null default 0 check (reorder_level >= 0),
  unit_cost_amount integer check (unit_cost_amount is null or unit_cost_amount >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique nulls not distinct (restaurant_id, branch_id, sku)
);

create table public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  movement_type text not null check (movement_type in ('purchase', 'waste', 'adjustment', 'sale', 'return')),
  quantity_delta numeric(14,3) not null check (quantity_delta <> 0),
  unit_cost_amount integer check (unit_cost_amount is null or unit_cost_amount >= 0),
  note text,
  recorded_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid references public.restaurants(id) on delete set null,
  actor_id uuid references auth.users(id) on delete set null,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create index audit_logs_restaurant_created_idx on public.audit_logs (restaurant_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin new.updated_at = now(); return new; end;
$$;

create or replace function public.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'), new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users for each row execute procedure public.create_profile_for_new_user();

create or replace function public.create_owner_membership()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.restaurant_memberships (restaurant_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict (restaurant_id, user_id) do update set role = 'owner', is_active = true;
  return new;
end;
$$;

create trigger on_restaurant_created
  after insert on public.restaurants for each row execute procedure public.create_owner_membership();

create or replace function public.protect_restaurant_owner()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.owner_id <> old.owner_id then
    raise exception 'Restaurant ownership can only be transferred by a privileged workflow';
  end if;
  return new;
end;
$$;

create trigger restaurants_protect_owner before update on public.restaurants
  for each row execute procedure public.protect_restaurant_owner();

create or replace function public.protect_owner_membership()
returns trigger language plpgsql set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    if old.role = 'owner' then
      raise exception 'Owner membership cannot be removed, changed, or deactivated';
    end if;
    return old;
  end if;
  if old.role = 'owner' and (new.role <> 'owner' or not new.is_active) then
    raise exception 'Owner membership cannot be removed, changed, or deactivated';
  end if;
  return new;
end;
$$;

create trigger memberships_protect_owner before update or delete on public.restaurant_memberships
  for each row execute procedure public.protect_owner_membership();

create or replace function public.assert_child_tenant()
returns trigger language plpgsql security definer set search_path = public as $$
declare parent_restaurant_id uuid;
begin
  if tg_table_name = 'order_items' then
    select restaurant_id into parent_restaurant_id from public.orders where id = new.order_id;
  elsif tg_table_name = 'order_status_history' then
    select restaurant_id into parent_restaurant_id from public.orders where id = new.order_id;
  elsif tg_table_name = 'kitchen_tickets' then
    select restaurant_id into parent_restaurant_id from public.orders where id = new.order_id;
  elsif tg_table_name = 'kitchen_ticket_items' then
    select restaurant_id into parent_restaurant_id from public.kitchen_tickets where id = new.kitchen_ticket_id;
  elsif tg_table_name = 'payments' then
    select restaurant_id into parent_restaurant_id from public.orders where id = new.order_id;
  elsif tg_table_name = 'payment_refunds' then
    select restaurant_id into parent_restaurant_id from public.payments where id = new.payment_id;
  elsif tg_table_name = 'inventory_movements' then
    select restaurant_id into parent_restaurant_id from public.inventory_items where id = new.inventory_item_id;
  end if;

  if parent_restaurant_id is null or parent_restaurant_id <> new.restaurant_id then
    raise exception 'Cross-restaurant reference is not allowed';
  end if;
  return new;
end;
$$;

create or replace function public.validate_order_update()
returns trigger language plpgsql set search_path = public as $$
begin
  if old.status in ('billed', 'paid') and (
    new.subtotal_amount <> old.subtotal_amount or new.discount_amount <> old.discount_amount
    or new.tax_amount <> old.tax_amount or new.service_charge_amount <> old.service_charge_amount
    or new.total_amount <> old.total_amount
  ) then
    raise exception 'Financial snapshots cannot change after billing';
  end if;

  if new.status <> old.status and not (
    (old.status = 'draft' and new.status in ('open', 'cancelled')) or
    (old.status = 'open' and new.status in ('sent_to_kitchen', 'cancelled')) or
    (old.status = 'sent_to_kitchen' and new.status in ('preparing', 'cancelled')) or
    (old.status = 'preparing' and new.status in ('ready', 'cancelled')) or
    (old.status = 'ready' and new.status in ('served', 'cancelled')) or
    (old.status = 'served' and new.status in ('billed', 'cancelled')) or
    (old.status = 'billed' and new.status = 'paid')
  ) then
    raise exception 'Invalid order status transition from % to %', old.status, new.status;
  end if;
  return new;
end;
$$;

create or replace function public.record_order_status_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status <> old.status then
    insert into public.order_status_history (restaurant_id, order_id, from_status, to_status, changed_by)
    values (new.restaurant_id, new.id, old.status, new.status, auth.uid());
  end if;
  return new;
end;
$$;

create or replace function public.write_audit_log()
returns trigger language plpgsql security definer set search_path = public as $$
declare row_data jsonb; row_id uuid; restaurant uuid;
begin
  row_data := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  row_id := (row_data ->> 'id')::uuid;
  restaurant := nullif(row_data ->> 'restaurant_id', '')::uuid;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, before_data, after_data)
  values (
    restaurant, auth.uid(), tg_table_name, row_id, lower(tg_op),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end
  );
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger orders_validate_update before update on public.orders
  for each row execute procedure public.validate_order_update();
create trigger orders_record_status after update on public.orders
  for each row execute procedure public.record_order_status_change();

create trigger order_items_tenant before insert or update on public.order_items
  for each row execute procedure public.assert_child_tenant();
create trigger order_status_history_tenant before insert or update on public.order_status_history
  for each row execute procedure public.assert_child_tenant();
create trigger kitchen_tickets_tenant before insert or update on public.kitchen_tickets
  for each row execute procedure public.assert_child_tenant();
create trigger kitchen_ticket_items_tenant before insert or update on public.kitchen_ticket_items
  for each row execute procedure public.assert_child_tenant();
create trigger payments_tenant before insert or update on public.payments
  for each row execute procedure public.assert_child_tenant();
create trigger payment_refunds_tenant before insert or update on public.payment_refunds
  for each row execute procedure public.assert_child_tenant();
create trigger inventory_movements_tenant before insert or update on public.inventory_movements
  for each row execute procedure public.assert_child_tenant();

create trigger orders_audit after insert or update or delete on public.orders
  for each row execute procedure public.write_audit_log();
create trigger payments_audit after insert on public.payments
  for each row execute procedure public.write_audit_log();
create trigger refunds_audit after insert on public.payment_refunds
  for each row execute procedure public.write_audit_log();

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'profiles', 'restaurants', 'restaurant_memberships', 'branches', 'dining_tables', 'customers',
    'menu_categories', 'menu_items', 'tax_rules', 'discounts', 'orders', 'order_items', 'kitchen_tickets',
    'kitchen_ticket_items', 'shifts', 'reservations', 'inventory_items'
  ] loop
    execute format('create trigger %I before update on public.%I for each row execute procedure public.set_updated_at()', table_name || '_set_updated_at', table_name);
  end loop;
end $$;

-- RLS is enabled for every application table. No table is readable by anon users.
alter table public.profiles enable row level security;
alter table public.restaurants enable row level security;
alter table public.restaurant_memberships enable row level security;
alter table public.branches enable row level security;
alter table public.dining_tables enable row level security;
alter table public.customers enable row level security;
alter table public.menu_categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.tax_rules enable row level security;
alter table public.discounts enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
alter table public.kitchen_tickets enable row level security;
alter table public.kitchen_ticket_items enable row level security;
alter table public.payments enable row level security;
alter table public.payment_refunds enable row level security;
alter table public.shifts enable row level security;
alter table public.cash_drawer_movements enable row level security;
alter table public.reservations enable row level security;
alter table public.inventory_items enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.audit_logs enable row level security;

create policy "profiles: view self or colleagues" on public.profiles for select to authenticated using (
  id = auth.uid() or exists (
    select 1 from public.restaurant_memberships mine
    join public.restaurant_memberships theirs on theirs.restaurant_id = mine.restaurant_id
    where mine.user_id = auth.uid() and mine.is_active and theirs.user_id = profiles.id and theirs.is_active
  )
);
create policy "profiles: create self" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "profiles: update self" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "restaurants: members read" on public.restaurants for select to authenticated using (public.is_restaurant_member(id));
create policy "restaurants: create owned" on public.restaurants for insert to authenticated with check (owner_id = auth.uid());
create policy "restaurants: owners update" on public.restaurants for update to authenticated using (public.has_restaurant_role(id, array['owner']::public.app_role[])) with check (public.has_restaurant_role(id, array['owner']::public.app_role[]));

create policy "memberships: members read" on public.restaurant_memberships for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "memberships: managers manage" on public.restaurant_memberships for insert to authenticated with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "memberships: managers update" on public.restaurant_memberships for update to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "memberships: owners delete" on public.restaurant_memberships for delete to authenticated using (public.has_restaurant_role(restaurant_id, array['owner']::public.app_role[]));

-- Catalog and configuration are owner/manager managed and member-readable.
create policy "branches: members read" on public.branches for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "branches: managers write" on public.branches for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "tables: members read" on public.dining_tables for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "tables: managers write" on public.dining_tables for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "categories: members read" on public.menu_categories for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "categories: managers write" on public.menu_categories for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "menu items: members read" on public.menu_items for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "menu items: managers write" on public.menu_items for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "tax rules: members read" on public.tax_rules for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "tax rules: managers write" on public.tax_rules for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "discounts: members read" on public.discounts for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "discounts: managers write" on public.discounts for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "inventory: members read" on public.inventory_items for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "inventory: managers write" on public.inventory_items for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));

-- Operational data is visible to restaurant staff, with narrowly scoped write roles.
create policy "customers: members read" on public.customers for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "customers: service staff write" on public.customers for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]));
create policy "orders: members read" on public.orders for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "orders: service staff insert" on public.orders for insert to authenticated with check (created_by = auth.uid() and public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]));
create policy "orders: service staff update" on public.orders for update to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]));
create policy "order items: members read" on public.order_items for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "order items: service staff write" on public.order_items for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]));
create policy "order history: members read" on public.order_status_history for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "tickets: members read" on public.kitchen_tickets for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "tickets: staff write" on public.kitchen_tickets for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'waiter', 'kitchen']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'waiter', 'kitchen']::public.app_role[]));
create policy "ticket items: members read" on public.kitchen_ticket_items for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "ticket items: staff write" on public.kitchen_ticket_items for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'waiter', 'kitchen']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'waiter', 'kitchen']::public.app_role[]));
create policy "payments: members read" on public.payments for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "payments: cashier insert" on public.payments for insert to authenticated with check (received_by = auth.uid() and public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier']::public.app_role[]));
create policy "refunds: members read" on public.payment_refunds for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "refunds: cashier insert" on public.payment_refunds for insert to authenticated with check (refunded_by = auth.uid() and public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier']::public.app_role[]));
create policy "shifts: members read" on public.shifts for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "shifts: cashiers write" on public.shifts for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier']::public.app_role[]));
create policy "cash movements: members read" on public.cash_drawer_movements for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "cash movements: cashiers insert" on public.cash_drawer_movements for insert to authenticated with check (recorded_by = auth.uid() and public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier']::public.app_role[]));
create policy "reservations: members read" on public.reservations for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "reservations: service staff write" on public.reservations for all to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[])) with check (public.has_restaurant_role(restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]));
create policy "inventory movements: members read" on public.inventory_movements for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "inventory movements: managers insert" on public.inventory_movements for insert to authenticated with check (recorded_by = auth.uid() and public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));
create policy "audit logs: managers read" on public.audit_logs for select to authenticated using (public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));

-- Storage object names are scoped as: <restaurant_id>/<filename>.
insert into storage.buckets (id, name, public)
values ('restaurant-assets', 'restaurant-assets', false)
on conflict (id) do nothing;

create policy "restaurant assets: members read" on storage.objects for select to authenticated using (
  bucket_id = 'restaurant-assets'
  and public.is_restaurant_member(nullif((storage.foldername(name))[1], '')::uuid)
);
create policy "restaurant assets: managers write" on storage.objects for insert to authenticated with check (
  bucket_id = 'restaurant-assets'
  and public.has_restaurant_role(nullif((storage.foldername(name))[1], '')::uuid, array['owner', 'manager']::public.app_role[])
);
create policy "restaurant assets: managers update" on storage.objects for update to authenticated using (
  bucket_id = 'restaurant-assets'
  and public.has_restaurant_role(nullif((storage.foldername(name))[1], '')::uuid, array['owner', 'manager']::public.app_role[])
) with check (
  bucket_id = 'restaurant-assets'
  and public.has_restaurant_role(nullif((storage.foldername(name))[1], '')::uuid, array['owner', 'manager']::public.app_role[])
);
create policy "restaurant assets: managers delete" on storage.objects for delete to authenticated using (
  bucket_id = 'restaurant-assets'
  and public.has_restaurant_role(nullif((storage.foldername(name))[1], '')::uuid, array['owner', 'manager']::public.app_role[])
);

-- Realtime tables used by the POS, kitchen display, and table map.
alter publication supabase_realtime add table public.orders, public.order_items, public.kitchen_tickets,
  public.kitchen_ticket_items, public.dining_tables, public.payments, public.reservations;
