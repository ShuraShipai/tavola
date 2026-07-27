-- A dining table's service state is derived from durable operational records.
-- Flutter may display it, but must never be the authority for Free/Occupied/
-- Billing/Reserved.  This migration also reconciles existing data once.

alter table public.dining_tables
  add column if not exists version integer not null default 1,
  add column if not exists current_status_detail text;

create or replace function public.reconcile_dining_table_state(p_table_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_table public.dining_tables%rowtype;
  v_status text;
  v_detail text;
begin
  if p_table_id is null then
    return;
  end if;

  select * into v_table
  from public.dining_tables
  where id = p_table_id
  for update;

  if not found or v_table.status = 'unavailable' then
    return;
  end if;

  if exists (
    select 1 from public.orders
    where table_id = v_table.id
      and status in ('open', 'sent_to_kitchen', 'preparing', 'ready', 'served', 'billed')
  ) then
    v_status := 'occupied';
    v_detail := case when exists (
      select 1 from public.orders
      where table_id = v_table.id and status = 'billed'
    ) then 'Billing' else 'Occupied' end;
  elsif exists (
    select 1 from public.reservations
    where table_id = v_table.id and status = 'seated'
  ) then
    v_status := 'occupied';
    v_detail := 'Occupied';
  elsif exists (
    select 1 from public.reservations
    where table_id = v_table.id and status in ('pending', 'confirmed')
  ) then
    v_status := 'reserved';
    v_detail := 'Reserved';
  else
    v_status := 'available';
    v_detail := null;
  end if;

  if v_table.status is distinct from v_status
     or v_table.current_status_detail is distinct from v_detail then
    update public.dining_tables
    set status = v_status,
        current_status_detail = v_detail,
        version = version + 1,
        updated_at = now()
    where id = v_table.id;
  end if;
end;
$$;

-- Lock and validate the table before an active order can claim it. This closes
-- the race where two devices could create concurrent active orders for one
-- table, while allowing takeaway/delivery orders with no table.
create or replace function public.validate_active_order_table_assignment()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_table public.dining_tables%rowtype;
begin
  if new.table_id is null
     or new.status not in ('open', 'sent_to_kitchen', 'preparing', 'ready', 'served', 'billed') then
    return new;
  end if;

  select * into v_table
  from public.dining_tables
  where id = new.table_id and restaurant_id = new.restaurant_id
  for update;

  if not found then
    raise exception 'Table does not belong to this restaurant' using errcode = '23503';
  end if;
  if v_table.status = 'unavailable' then
    raise exception 'This table is unavailable' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.orders
    where table_id = new.table_id
      and id <> new.id
      and status in ('open', 'sent_to_kitchen', 'preparing', 'ready', 'served', 'billed')
  ) then
    raise exception 'This table already has an active order' using errcode = '23505';
  end if;
  return new;
end;
$$;

create or replace function public.reconcile_dining_table_state_from_order()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'DELETE' then
    perform public.reconcile_dining_table_state(old.table_id);
  else
    perform public.reconcile_dining_table_state(new.table_id);
    if tg_op = 'UPDATE' and old.table_id is distinct from new.table_id then
      perform public.reconcile_dining_table_state(old.table_id);
    end if;
  end if;
  return null;
end;
$$;

create or replace function public.reconcile_dining_table_state_from_reservation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'DELETE' then
    perform public.reconcile_dining_table_state(old.table_id);
  else
    perform public.reconcile_dining_table_state(new.table_id);
    if tg_op = 'UPDATE' and old.table_id is distinct from new.table_id then
      perform public.reconcile_dining_table_state(old.table_id);
    end if;
  end if;
  return null;
end;
$$;

drop trigger if exists orders_validate_active_table_assignment on public.orders;
create trigger orders_validate_active_table_assignment
before insert or update of table_id, status on public.orders
for each row execute function public.validate_active_order_table_assignment();

drop trigger if exists orders_reconcile_dining_table_state on public.orders;
create trigger orders_reconcile_dining_table_state
after insert or update of table_id, status or delete on public.orders
for each row execute function public.reconcile_dining_table_state_from_order();

drop trigger if exists reservations_reconcile_dining_table_state on public.reservations;
create trigger reservations_reconcile_dining_table_state
after insert or update of table_id, status or delete on public.reservations
for each row execute function public.reconcile_dining_table_state_from_reservation();

-- Table setup edits (number/capacity) must not overwrite a state derived from
-- orders or reservations. Keep the existing RPC signature for deployed
-- clients, but deliberately ignore its former display-caption parameter.
create or replace function public.save_dining_table(
  p_restaurant_id uuid,
  p_table_id uuid default null,
  p_branch_id uuid default null,
  p_label text default null,
  p_capacity integer default null,
  p_sort_order integer default 0,
  p_current_status_detail text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_branch_id uuid;
  v_table_id uuid;
  v_existing public.dining_tables%rowtype;
begin
  if auth.uid() is null or not public.has_restaurant_role(
    p_restaurant_id, array['owner', 'manager']::public.app_role[]
  ) then
    raise exception 'You are not permitted to save tables' using errcode = '42501';
  end if;
  if nullif(trim(coalesce(p_label, '')), '') is null
     or p_capacity not between 1 and 100
     or p_sort_order < 0 then
    raise exception 'Table name, capacity, or number is invalid' using errcode = '22023';
  end if;

  if p_table_id is not null then
    select * into v_existing from public.dining_tables where id = p_table_id for update;
    if not found or v_existing.restaurant_id <> p_restaurant_id then
      raise exception 'Table not found' using errcode = 'P0002';
    end if;
  end if;

  v_branch_id := coalesce(p_branch_id, v_existing.branch_id);
  if v_branch_id is null then
    select id into v_branch_id from public.branches
    where restaurant_id = p_restaurant_id and is_active
    order by created_at, id limit 1;
  end if;
  if not exists (
    select 1 from public.branches
    where id = v_branch_id and restaurant_id = p_restaurant_id and is_active
  ) then
    raise exception 'No active dining area is available' using errcode = '23503';
  end if;

  if p_table_id is null then
    insert into public.dining_tables (
      restaurant_id, branch_id, label, capacity, sort_order, status, version,
      current_status_detail
    ) values (
      p_restaurant_id, v_branch_id, trim(p_label), p_capacity, p_sort_order,
      'available', 1, null
    ) returning id into v_table_id;
  else
    update public.dining_tables
    set label = trim(p_label),
        capacity = p_capacity,
        sort_order = p_sort_order,
        updated_at = now()
    where id = p_table_id
    returning id into v_table_id;
  end if;

  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action)
  values (
    p_restaurant_id, auth.uid(), 'dining_table', v_table_id,
    case when p_table_id is null then 'created' else 'updated' end
  );
  return v_table_id;
end;
$$;

-- Reconcile pre-existing rows after enabling the triggers.
do $$
declare v_table_id uuid;
begin
  for v_table_id in select id from public.dining_tables loop
    perform public.reconcile_dining_table_state(v_table_id);
  end loop;
end;
$$;

revoke all on function public.reconcile_dining_table_state(uuid) from public;
revoke all on function public.save_dining_table(uuid, uuid, uuid, text, integer, integer, text) from public;
grant execute on function public.save_dining_table(uuid, uuid, uuid, text, integer, integer, text) to authenticated;
