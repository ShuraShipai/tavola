-- POS order edits and kitchen progression must be server-authoritative.  These
-- routines snapshot menu data, recalculate integer-minor totals, and prevent a
-- client from skipping an operational state or forging a kitchen ticket.

alter table public.order_items
  add constraint order_items_amounts_match_snapshot
  check (
    discount_amount <= round(unit_price_amount * quantity)::integer
    and line_total_amount = round(unit_price_amount * quantity)::integer - discount_amount + tax_amount
  ) not valid;

alter table public.order_items validate constraint order_items_amounts_match_snapshot;

create unique index if not exists kitchen_tickets_one_per_order_idx
  on public.kitchen_tickets (order_id);
create index if not exists kitchen_tickets_restaurant_status_created_idx
  on public.kitchen_tickets (restaurant_id, status, created_at);
create index if not exists kitchen_ticket_items_ticket_status_idx
  on public.kitchen_ticket_items (kitchen_ticket_id, status);

-- Direct PostgREST mutations would allow a service user to alter a snapshot or
-- create a ticket for another order.  Creation and edits use these RPCs instead.
revoke insert, update, delete on public.order_items from anon, authenticated;
revoke update, delete on public.orders from anon, authenticated;
revoke insert, update, delete on public.kitchen_tickets from anon, authenticated;
revoke insert, update, delete on public.kitchen_ticket_items from anon, authenticated;

create or replace function public.replace_open_order_items(
  p_order_id uuid,
  p_items jsonb,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor_id uuid := auth.uid();
  v_order public.orders%rowtype;
  v_item jsonb;
  v_menu_item public.menu_items%rowtype;
  v_menu_item_id uuid;
  v_quantity numeric(12, 3);
  v_line_subtotal integer;
  v_line_tax integer;
  v_subtotal integer := 0;
  v_tax integer := 0;
begin
  if v_actor_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'An order requires at least one item' using errcode = '22023';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
  if v_order.status <> 'open' then
    raise exception 'Only open orders can be edited' using errcode = '22023';
  end if;
  if not public.has_restaurant_role(v_order.restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]) then
    raise exception 'You are not permitted to edit this order' using errcode = '42501';
  end if;

  delete from public.order_items where order_id = p_order_id;
  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object'
       or nullif(v_item ->> 'menu_item_id', '') is null
       or nullif(v_item ->> 'quantity', '') is null
       or jsonb_typeof(coalesce(v_item -> 'modifiers', '[]'::jsonb)) <> 'array' then
      raise exception 'Each item requires menu_item_id, quantity, and array modifiers' using errcode = '22023';
    end if;
    begin
      v_menu_item_id := (v_item ->> 'menu_item_id')::uuid;
      v_quantity := (v_item ->> 'quantity')::numeric(12, 3);
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'Item menu_item_id or quantity is invalid' using errcode = '22023';
    end;
    if v_quantity <= 0 then
      raise exception 'Item quantity must be greater than zero' using errcode = '22023';
    end if;

    select * into v_menu_item from public.menu_items
     where id = v_menu_item_id and restaurant_id = v_order.restaurant_id
       and is_active and is_available;
    if not found then
      raise exception 'Menu item % is unavailable for this restaurant', v_menu_item_id using errcode = '23503';
    end if;
    v_line_subtotal := round(v_menu_item.price_amount * v_quantity)::integer;
    v_line_tax := round(v_line_subtotal * v_menu_item.tax_rate_basis_points / 10000.0)::integer;
    v_subtotal := v_subtotal + v_line_subtotal;
    v_tax := v_tax + v_line_tax;
    insert into public.order_items (
      restaurant_id, order_id, menu_item_id, item_name, sku_snapshot,
      unit_price_amount, quantity, discount_amount, tax_amount, line_total_amount,
      modifiers, notes
    ) values (
      v_order.restaurant_id, v_order.id, v_menu_item.id, v_menu_item.name, v_menu_item.sku,
      v_menu_item.price_amount, v_quantity, 0, v_line_tax, v_line_subtotal + v_line_tax,
      coalesce(v_item -> 'modifiers', '[]'::jsonb), nullif(v_item ->> 'notes', '')
    );
  end loop;
  update public.orders set
    notes = coalesce(nullif(p_notes, ''), notes),
    subtotal_amount = v_subtotal, discount_amount = 0, tax_amount = v_tax,
    service_charge_amount = 0, total_amount = v_subtotal + v_tax
  where id = v_order.id;
end;
$$;

create or replace function public.submit_order_to_kitchen(p_order_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor_id uuid := auth.uid();
  v_order public.orders%rowtype;
  v_ticket_id uuid;
begin
  if v_actor_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'Order not found' using errcode = 'P0002'; end if;
  if v_order.status <> 'open' then
    raise exception 'Only open orders can be sent to kitchen' using errcode = '22023';
  end if;
  if not public.has_restaurant_role(v_order.restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]) then
    raise exception 'You are not permitted to send this order' using errcode = '42501';
  end if;
  if not exists (select 1 from public.order_items where order_id = v_order.id) then
    raise exception 'An order requires at least one item' using errcode = '22023';
  end if;

  insert into public.kitchen_tickets (restaurant_id, order_id, status)
  values (v_order.restaurant_id, v_order.id, 'queued') returning id into v_ticket_id;
  insert into public.kitchen_ticket_items (restaurant_id, kitchen_ticket_id, order_item_id, status, notes)
    select v_order.restaurant_id, v_ticket_id, id, 'queued', notes
      from public.order_items where order_id = v_order.id;
  update public.orders set status = 'sent_to_kitchen' where id = v_order.id;
  return v_ticket_id;
end;
$$;

-- Matches the POS repository contract.  The order identity and tenant are
-- checked before updating any mutable order metadata or its recalculated lines.
create or replace function public.update_order(
  p_order_id uuid,
  p_restaurant_id uuid,
  p_branch_id uuid,
  p_items jsonb,
  p_table_id uuid default null,
  p_customer_id uuid default null,
  p_order_type text default 'dine_in',
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_order public.orders%rowtype;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_order.restaurant_id <> p_restaurant_id then
    raise exception 'Order not found for this restaurant' using errcode = 'P0002';
  end if;
  if v_order.status <> 'open' then
    raise exception 'Only open orders can be edited' using errcode = '22023';
  end if;
  if p_order_type not in ('dine_in', 'takeaway', 'delivery') then
    raise exception 'Unsupported order type' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.branches where id = p_branch_id
      and restaurant_id = p_restaurant_id and is_active
  ) then
    raise exception 'Branch does not belong to this restaurant or is inactive' using errcode = '23503';
  end if;
  if p_table_id is not null and not exists (
    select 1 from public.dining_tables where id = p_table_id
      and restaurant_id = p_restaurant_id and branch_id = p_branch_id
  ) then
    raise exception 'Table does not belong to this restaurant branch' using errcode = '23503';
  end if;
  if p_customer_id is not null and not exists (
    select 1 from public.customers where id = p_customer_id and restaurant_id = p_restaurant_id
  ) then
    raise exception 'Customer does not belong to this restaurant' using errcode = '23503';
  end if;

  -- This performs the permission check, menu snapshots, and total calculation.
  perform public.replace_open_order_items(p_order_id, p_items, p_notes);
  update public.orders set branch_id = p_branch_id, table_id = p_table_id,
    customer_id = p_customer_id, order_type = p_order_type,
    notes = nullif(p_notes, '')
  where id = p_order_id;
  return p_order_id;
end;
$$;

-- Generic POS state action.  Kitchen preparation progression is intentionally
-- delegated to update_kitchen_ticket_status so ticket and order views stay in
-- lockstep.  Sending an order creates its immutable ticket snapshot.
create or replace function public.transition_order_status(
  p_order_id uuid,
  p_restaurant_id uuid,
  p_to_status text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_order public.orders%rowtype;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_order.restaurant_id <> p_restaurant_id then
    raise exception 'Order not found for this restaurant' using errcode = 'P0002';
  end if;
  if p_to_status = 'sent_to_kitchen' then
    perform public.submit_order_to_kitchen(p_order_id);
    return;
  end if;
  if p_to_status in ('preparing', 'ready', 'served') then
    raise exception 'Kitchen status must be changed through its ticket' using errcode = '22023';
  end if;
  if p_to_status = 'cancelled' then
    if not public.has_restaurant_role(v_order.restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]) then
      raise exception 'You are not permitted to cancel this order' using errcode = '42501';
    end if;
    update public.kitchen_ticket_items set status = 'cancelled'
      where kitchen_ticket_id in (select id from public.kitchen_tickets where order_id = p_order_id)
        and status <> 'cancelled';
    update public.kitchen_tickets set status = 'cancelled'
      where order_id = p_order_id and status <> 'cancelled';
  elsif p_to_status in ('billed', 'paid') then
    if not public.has_restaurant_role(v_order.restaurant_id, array['owner', 'manager', 'cashier']::public.app_role[]) then
      raise exception 'You are not permitted to bill or settle this order' using errcode = '42501';
    end if;
  else
    raise exception 'Unsupported order status' using errcode = '22023';
  end if;
  update public.orders set status = p_to_status::public.order_status where id = p_order_id;
end;
$$;

create or replace function public.update_kitchen_ticket_status(
  p_ticket_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_ticket public.kitchen_tickets%rowtype;
  v_order_status public.order_status;
begin
  select * into v_ticket from public.kitchen_tickets where id = p_ticket_id for update;
  if not found then raise exception 'Kitchen ticket not found' using errcode = 'P0002'; end if;
  if not public.has_restaurant_role(v_ticket.restaurant_id, array['owner', 'manager', 'kitchen']::public.app_role[]) then
    raise exception 'You are not permitted to update this ticket' using errcode = '42501';
  end if;
  if not (
    (v_ticket.status = 'queued' and p_status in ('preparing', 'cancelled')) or
    (v_ticket.status = 'preparing' and p_status in ('ready', 'cancelled')) or
    (v_ticket.status = 'ready' and p_status = 'served')
  ) then
    raise exception 'Invalid kitchen ticket status transition from % to %', v_ticket.status, p_status using errcode = '22023';
  end if;

  update public.kitchen_tickets set status = p_status,
    started_at = case when p_status = 'preparing' then now() else started_at end,
    ready_at = case when p_status = 'ready' then now() else ready_at end
  where id = v_ticket.id;
  update public.kitchen_ticket_items set status = p_status where kitchen_ticket_id = v_ticket.id;

  v_order_status := case p_status
    when 'preparing' then 'preparing'::public.order_status
    when 'ready' then 'ready'::public.order_status
    when 'served' then 'served'::public.order_status
    when 'cancelled' then 'cancelled'::public.order_status
  end;
  update public.orders set status = v_order_status
    where id = v_ticket.order_id and status <> v_order_status;
end;
$$;

revoke all on function public.replace_open_order_items(uuid, jsonb, text) from public, anon;
revoke all on function public.submit_order_to_kitchen(uuid) from public, anon;
revoke all on function public.update_kitchen_ticket_status(uuid, text) from public, anon;
revoke all on function public.update_order(uuid, uuid, uuid, jsonb, uuid, uuid, text, text) from public, anon;
revoke all on function public.transition_order_status(uuid, uuid, text) from public, anon;
grant execute on function public.replace_open_order_items(uuid, jsonb, text) to authenticated;
grant execute on function public.submit_order_to_kitchen(uuid) to authenticated;
grant execute on function public.update_kitchen_ticket_status(uuid, text) to authenticated;
grant execute on function public.update_order(uuid, uuid, uuid, jsonb, uuid, uuid, text, text) to authenticated;
grant execute on function public.transition_order_status(uuid, uuid, text) to authenticated;
