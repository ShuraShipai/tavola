-- Held orders remain editable until they are submitted to the kitchen.  The
-- item replacement helper already protects draft/open edits and recalculates
-- all monetary snapshots; this RPC must use the same status boundary.

create or replace function public.update_order(
  p_order_id uuid,
  p_restaurant_id uuid,
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
  if v_order.status not in ('draft', 'open') then
    raise exception 'Only held or open orders can be edited' using errcode = '22023';
  end if;
  if p_order_type not in ('dine_in', 'takeaway', 'delivery') then
    raise exception 'Unsupported order type' using errcode = '22023';
  end if;
  if p_table_id is not null and not exists (
    select 1 from public.dining_tables
    where id = p_table_id and restaurant_id = p_restaurant_id
  ) then
    raise exception 'Table does not belong to this restaurant' using errcode = '23503';
  end if;
  if p_customer_id is not null and not exists (
    select 1 from public.customers
    where id = p_customer_id and restaurant_id = p_restaurant_id
  ) then
    raise exception 'Customer does not belong to this restaurant' using errcode = '23503';
  end if;
  perform public.replace_open_order_items(p_order_id, p_items, p_notes);
  update public.orders
  set table_id = p_table_id,
      customer_id = p_customer_id,
      order_type = p_order_type,
      notes = nullif(p_notes, '')
  where id = p_order_id;
  return p_order_id;
end;
$$;
