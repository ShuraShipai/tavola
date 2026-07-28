-- Billing is settled only through this transaction.  The actor and restaurant
-- are derived from the authenticated session and historical payment facts are
-- append-only.
revoke insert, update, delete on public.payments, public.payment_refunds from anon, authenticated;

create or replace function public.collect_order_payment(
  p_order_id uuid,
  p_payment_method text,
  p_amount integer,
  p_external_reference text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor_id uuid := auth.uid();
  v_order public.orders%rowtype;
  v_received integer;
  v_payment_id uuid;
begin
  if v_actor_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;
  if p_payment_method not in ('cash', 'card', 'upi', 'wallet', 'bank_transfer', 'other') then
    raise exception 'Unsupported payment method' using errcode = '22023';
  end if;
  if p_amount <= 0 then
    raise exception 'Payment amount must be positive' using errcode = '22023';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'Order not found' using errcode = 'P0002'; end if;
  if not public.has_restaurant_role(v_order.restaurant_id, array['owner', 'manager', 'cashier']::public.app_role[]) then
    raise exception 'You are not permitted to collect payment' using errcode = '42501';
  end if;
  if v_order.status not in ('served', 'billed') then
    raise exception 'Only served or billed orders can be settled' using errcode = '22023';
  end if;

  select coalesce(sum(amount), 0)::integer into v_received
    from public.payments where order_id = v_order.id and status = 'completed';
  if p_amount > v_order.total_amount - v_received then
    raise exception 'Payment exceeds amount due' using errcode = '22023';
  end if;

  insert into public.payments (restaurant_id, order_id, payment_method, amount, external_reference, received_by)
  values (v_order.restaurant_id, v_order.id, p_payment_method, p_amount, nullif(p_external_reference, ''), v_actor_id)
  returning id into v_payment_id;

  v_received := v_received + p_amount;
  update public.orders set status = case when v_received = v_order.total_amount then 'paid'::public.order_status else 'billed'::public.order_status end,
    closed_at = case when v_received = v_order.total_amount then now() else closed_at end
  where id = v_order.id;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data)
  values (v_order.restaurant_id, v_actor_id, 'payment', v_payment_id, 'payment_collected',
    jsonb_build_object('order_id', v_order.id, 'amount', p_amount, 'method', p_payment_method, 'settled_amount', v_received));
  return v_payment_id;
end;
$$;

revoke all on function public.collect_order_payment(uuid, text, integer, text) from public, anon;
grant execute on function public.collect_order_payment(uuid, text, integer, text) to authenticated;
