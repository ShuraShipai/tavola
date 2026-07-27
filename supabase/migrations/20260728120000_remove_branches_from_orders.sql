-- Orders are restaurant-scoped. Branch ownership belongs to tables and
-- reservations, not to an order record or the order-creation workflow.
drop function if exists public.create_order(uuid, uuid, jsonb, uuid, uuid, text, text);
drop function if exists public.update_order(uuid, uuid, uuid, jsonb, uuid, uuid, text, text);

alter table public.orders drop column if exists branch_id;

create function public.create_order(
  p_restaurant_id uuid,
  p_items jsonb,
  p_table_id uuid default null,
  p_customer_id uuid default null,
  p_order_type text default 'dine_in',
  p_notes text default null
)
returns uuid
language plpgsql security definer set search_path = public, pg_temp
as $$
declare v_actor uuid := auth.uid(); v_order_id uuid; v_order_number bigint;
begin
  if v_actor is null then raise exception 'Authentication is required' using errcode = '28000'; end if;
  if p_restaurant_id is null then raise exception 'Restaurant is required' using errcode = '22023'; end if;
  if p_order_type not in ('dine_in', 'takeaway', 'delivery') then raise exception 'Unsupported order type' using errcode = '22023'; end if;
  if not public.has_restaurant_role(p_restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then raise exception 'You are not permitted to create orders for this restaurant' using errcode = '42501'; end if;
  if p_table_id is not null and not exists (select 1 from public.dining_tables where id = p_table_id and restaurant_id = p_restaurant_id) then raise exception 'Table does not belong to this restaurant' using errcode = '23503'; end if;
  if p_customer_id is not null and not exists (select 1 from public.customers where id = p_customer_id and restaurant_id = p_restaurant_id) then raise exception 'Customer does not belong to this restaurant' using errcode = '23503'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_restaurant_id::text, 0));
  select coalesce(max(order_number), 0) + 1 into v_order_number from public.orders where restaurant_id = p_restaurant_id;
  insert into public.orders (restaurant_id, order_number, table_id, customer_id, status, order_type, notes, subtotal_amount, discount_amount, tax_amount, service_charge_amount, total_amount, created_by, opened_at)
  values (p_restaurant_id, v_order_number, p_table_id, p_customer_id, 'open', p_order_type, nullif(p_notes, ''), 0, 0, 0, 0, 0, v_actor, now()) returning id into v_order_id;
  perform public.replace_open_order_items(v_order_id, p_items, p_notes);
  return v_order_id;
end;
$$;

create function public.update_order(
  p_order_id uuid,
  p_restaurant_id uuid,
  p_items jsonb,
  p_table_id uuid default null,
  p_customer_id uuid default null,
  p_order_type text default 'dine_in',
  p_notes text default null
)
returns uuid
language plpgsql security definer set search_path = public, pg_temp
as $$
declare v_order public.orders%rowtype;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_order.restaurant_id <> p_restaurant_id then raise exception 'Order not found for this restaurant' using errcode = 'P0002'; end if;
  if v_order.status <> 'open' then raise exception 'Only open orders can be edited' using errcode = '22023'; end if;
  if p_order_type not in ('dine_in', 'takeaway', 'delivery') then raise exception 'Unsupported order type' using errcode = '22023'; end if;
  if p_table_id is not null and not exists (select 1 from public.dining_tables where id = p_table_id and restaurant_id = p_restaurant_id) then raise exception 'Table does not belong to this restaurant' using errcode = '23503'; end if;
  if p_customer_id is not null and not exists (select 1 from public.customers where id = p_customer_id and restaurant_id = p_restaurant_id) then raise exception 'Customer does not belong to this restaurant' using errcode = '23503'; end if;
  perform public.replace_open_order_items(p_order_id, p_items, p_notes);
  update public.orders set table_id = p_table_id, customer_id = p_customer_id, order_type = p_order_type, notes = nullif(p_notes, '') where id = p_order_id;
  return p_order_id;
end;
$$;

create or replace function public.assign_order_table(p_order_id uuid, p_table_id uuid, p_expected_table_version integer)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_order public.orders%rowtype; v_table public.dining_tables%rowtype; v_actor uuid := auth.uid();
begin
  if v_actor is null then raise exception 'Authentication is required' using errcode = '28000'; end if;
  select * into v_order from public.orders where id = p_order_id for update;
  select * into v_table from public.dining_tables where id = p_table_id for update;
  if not found or v_order.restaurant_id <> v_table.restaurant_id then raise exception 'Order and table must belong to the same restaurant' using errcode = '23503'; end if;
  if not public.has_restaurant_role(v_order.restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then raise exception 'You are not permitted to assign tables' using errcode = '42501'; end if;
  if v_order.status <> 'open' then raise exception 'Only open orders can be assigned' using errcode = '22023'; end if;
  if v_table.version <> p_expected_table_version then raise exception 'Table was changed by another device; refresh and try again' using errcode = '40001'; end if;
  if v_table.status not in ('available','reserved','occupied') then raise exception 'Table is unavailable' using errcode = '22023'; end if;
  if exists (select 1 from public.orders o where o.table_id = v_table.id and o.id <> v_order.id and o.status in ('open','sent_to_kitchen','preparing','ready','served','billed')) then raise exception 'Table already has an active order' using errcode = '23505'; end if;
  update public.dining_tables set status = 'occupied', version = version + 1 where id = v_table.id;
  update public.orders set table_id = v_table.id where id = v_order.id;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data) values (v_order.restaurant_id, v_actor, 'order', v_order.id, 'table_assigned', jsonb_build_object('table_id', v_table.id));
end;
$$;

revoke all on function public.create_order(uuid, jsonb, uuid, uuid, text, text) from public, anon;
revoke all on function public.update_order(uuid, uuid, jsonb, uuid, uuid, text, text) from public, anon;
grant execute on function public.create_order(uuid, jsonb, uuid, uuid, text, text) to authenticated;
grant execute on function public.update_order(uuid, uuid, jsonb, uuid, uuid, text, text) to authenticated;
