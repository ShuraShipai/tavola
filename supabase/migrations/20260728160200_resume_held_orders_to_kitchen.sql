-- A held order is a draft until staff explicitly submit it.  Resuming and
-- submitting in one transaction preserves the status history and prevents a
-- draft from being stranded outside the kitchen workflow.

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
  select * into v_order from public.orders
  where id = p_order_id and restaurant_id = p_restaurant_id
  for update;
  if not found then
    raise exception 'Order not found for this restaurant' using errcode = 'P0002';
  end if;

  if p_to_status = 'sent_to_kitchen' then
    if v_order.status = 'draft' then
      if not public.has_restaurant_role(
        v_order.restaurant_id,
        array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]
      ) then
        raise exception 'You are not permitted to send this order' using errcode = '42501';
      end if;
      update public.orders
      set status = 'open', opened_at = coalesce(opened_at, now())
      where id = v_order.id;
    end if;
    perform public.submit_order_to_kitchen(p_order_id);
    return;
  end if;

  if p_to_status = 'cancelled' then
    if not public.has_restaurant_role(
      v_order.restaurant_id,
      array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]
    ) then
      raise exception 'You are not permitted to cancel this order' using errcode = '42501';
    end if;
    if v_order.status in ('paid', 'cancelled') then
      raise exception 'This order cannot be cancelled' using errcode = '22023';
    end if;
    update public.kitchen_ticket_items
    set status = 'cancelled'
    where kitchen_ticket_id in (
      select id from public.kitchen_tickets where order_id = p_order_id
    ) and status <> 'cancelled';
    update public.kitchen_tickets
    set status = 'cancelled'
    where order_id = p_order_id and status <> 'cancelled';
    update public.orders set status = 'cancelled' where id = p_order_id;
    return;
  end if;

  raise exception 'Only kitchen transitions, cancellation, and payment settlement are supported'
    using errcode = '22023';
end;
$$;
