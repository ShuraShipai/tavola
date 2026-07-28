-- Cancellation needs an explicit staff reason in addition to the protected
-- order state transition. The reason is immutable operational audit data.

create or replace function public.cancel_restaurant_order(
  p_order_id uuid,
  p_restaurant_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_order public.orders%rowtype;
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
begin
  if v_reason is null or char_length(v_reason) > 500 then
    raise exception 'A cancellation reason of up to 500 characters is required'
      using errcode = '22023';
  end if;

  select * into v_order from public.orders
  where id = p_order_id and restaurant_id = p_restaurant_id
  for update;
  if not found then
    raise exception 'Order not found for this restaurant' using errcode = 'P0002';
  end if;

  perform public.transition_order_status(p_order_id, p_restaurant_id, 'cancelled');

  insert into public.audit_logs (
    restaurant_id, actor_id, entity_type, entity_id, action, before_data, after_data
  ) values (
    v_order.restaurant_id,
    auth.uid(),
    'order',
    v_order.id,
    'cancelled',
    jsonb_build_object('status', v_order.status),
    jsonb_build_object('status', 'cancelled', 'reason', v_reason)
  );
end;
$$;

revoke all on function public.cancel_restaurant_order(uuid, uuid, text) from public, anon;
grant execute on function public.cancel_restaurant_order(uuid, uuid, text) to authenticated;
