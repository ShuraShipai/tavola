-- Atomic order creation. Client-supplied prices, tax totals, order numbers and
-- actor ids are deliberately not accepted by this API.
create or replace function public.create_order(
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
  v_actor_id uuid := auth.uid();
  v_role public.app_role;
  v_order_id uuid;
  v_order_number bigint;
  v_item jsonb;
  v_lines jsonb := '[]'::jsonb;
  v_menu_item_id uuid;
  v_item_name text;
  v_sku text;
  v_unit_price integer;
  v_tax_rate integer;
  v_quantity numeric(12, 3);
  v_line_subtotal integer;
  v_line_tax integer;
  v_subtotal integer := 0;
  v_tax integer := 0;
  v_line jsonb;
begin
  if v_actor_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if p_restaurant_id is null or p_branch_id is null then
    raise exception 'Restaurant and branch are required' using errcode = '22023';
  end if;

  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'An order requires at least one item' using errcode = '22023';
  end if;

  select membership.role
    into v_role
    from public.restaurant_memberships membership
   where membership.restaurant_id = p_restaurant_id
     and membership.user_id = v_actor_id
     and membership.is_active;

  if v_role is null or v_role not in ('owner', 'manager', 'cashier', 'waiter') then
    raise exception 'You are not permitted to create orders for this restaurant' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.branches branch
     where branch.id = p_branch_id
       and branch.restaurant_id = p_restaurant_id
       and branch.is_active
  ) then
    raise exception 'Branch does not belong to this restaurant or is inactive' using errcode = '23503';
  end if;

  if p_table_id is not null and not exists (
    select 1 from public.dining_tables dining_table
     where dining_table.id = p_table_id
       and dining_table.restaurant_id = p_restaurant_id
       and dining_table.branch_id = p_branch_id
  ) then
    raise exception 'Table does not belong to this restaurant branch' using errcode = '23503';
  end if;

  if p_customer_id is not null and not exists (
    select 1 from public.customers customer
     where customer.id = p_customer_id
       and customer.restaurant_id = p_restaurant_id
  ) then
    raise exception 'Customer does not belong to this restaurant' using errcode = '23503';
  end if;

  if p_order_type not in ('dine_in', 'takeaway', 'delivery') then
    raise exception 'Unsupported order type' using errcode = '22023';
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    if jsonb_typeof(v_item) <> 'object'
       or nullif(v_item ->> 'menu_item_id', '') is null
       or nullif(v_item ->> 'quantity', '') is null then
      raise exception 'Each item requires menu_item_id and quantity' using errcode = '22023';
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

    if jsonb_typeof(coalesce(v_item -> 'modifiers', '[]'::jsonb)) <> 'array' then
      raise exception 'Item modifiers must be an array' using errcode = '22023';
    end if;

    select menu_item.name, menu_item.sku, menu_item.price_amount, menu_item.tax_rate_basis_points
      into v_item_name, v_sku, v_unit_price, v_tax_rate
      from public.menu_items menu_item
     where menu_item.id = v_menu_item_id
       and menu_item.restaurant_id = p_restaurant_id
       and menu_item.is_active
       and menu_item.is_available;

    if not found then
      raise exception 'Menu item % is unavailable for this restaurant', v_menu_item_id using errcode = '23503';
    end if;

    v_line_subtotal := round(v_unit_price * v_quantity)::integer;
    v_line_tax := round(v_line_subtotal * v_tax_rate / 10000.0)::integer;
    v_subtotal := v_subtotal + v_line_subtotal;
    v_tax := v_tax + v_line_tax;
    v_lines := v_lines || jsonb_build_array(jsonb_build_object(
      'menu_item_id', v_menu_item_id,
      'item_name', v_item_name,
      'sku_snapshot', v_sku,
      'unit_price_amount', v_unit_price,
      'quantity', v_quantity,
      'tax_amount', v_line_tax,
      'line_total_amount', v_line_subtotal + v_line_tax,
      'modifiers', coalesce(v_item -> 'modifiers', '[]'::jsonb),
      'notes', nullif(v_item ->> 'notes', '')
    ));
  end loop;

  -- Serialise number allocation per restaurant without a mutable client-side counter.
  perform pg_advisory_xact_lock(hashtextextended(p_restaurant_id::text, 0));
  select coalesce(max(order_number), 0) + 1
    into v_order_number
    from public.orders
   where restaurant_id = p_restaurant_id;

  insert into public.orders (
    restaurant_id, branch_id, order_number, table_id, customer_id, status,
    order_type, notes, subtotal_amount, discount_amount, tax_amount,
    service_charge_amount, total_amount, created_by, opened_at
  ) values (
    p_restaurant_id, p_branch_id, v_order_number, p_table_id, p_customer_id, 'open',
    p_order_type, nullif(p_notes, ''), v_subtotal, 0, v_tax, 0, v_subtotal + v_tax,
    v_actor_id, now()
  ) returning id into v_order_id;

  for v_line in select value from jsonb_array_elements(v_lines)
  loop
    insert into public.order_items (
      restaurant_id, order_id, menu_item_id, item_name, sku_snapshot,
      unit_price_amount, quantity, discount_amount, tax_amount, line_total_amount,
      modifiers, notes
    ) values (
      p_restaurant_id, v_order_id, (v_line ->> 'menu_item_id')::uuid,
      v_line ->> 'item_name', nullif(v_line ->> 'sku_snapshot', ''),
      (v_line ->> 'unit_price_amount')::integer, (v_line ->> 'quantity')::numeric(12, 3),
      0, (v_line ->> 'tax_amount')::integer, (v_line ->> 'line_total_amount')::integer,
      v_line -> 'modifiers', nullif(v_line ->> 'notes', '')
    );
  end loop;

  return v_order_id;
end;
$$;

-- Orders must enter through the SECURITY DEFINER RPC so that server-side
-- snapshots and totals cannot be bypassed by a direct PostgREST insert.
revoke insert on table public.orders, public.order_items from anon, authenticated;
revoke all on function public.create_order(uuid, uuid, jsonb, uuid, uuid, text, text) from public, anon;
grant execute on function public.create_order(uuid, uuid, jsonb, uuid, uuid, text, text) to authenticated;
