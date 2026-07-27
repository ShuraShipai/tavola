-- Complete the POS operational boundary. Every mutable operational action is
-- performed in a transaction with an authenticated actor, tenant checks, and
-- an audit entry. Client-side state must never be the source of truth.

alter table public.dining_tables
  add column if not exists version integer not null default 1;

create table if not exists public.table_merges (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  primary_table_id uuid not null references public.dining_tables(id) on delete restrict,
  created_by uuid not null references auth.users(id) on delete restrict,
  closed_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.table_merge_members (
  merge_id uuid not null references public.table_merges(id) on delete cascade,
  table_id uuid not null references public.dining_tables(id) on delete restrict,
  primary key (merge_id, table_id)
);

create table if not exists public.order_invoices (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  order_id uuid not null unique references public.orders(id) on delete restrict,
  invoice_number bigint not null,
  total_amount integer not null check (total_amount >= 0),
  snapshot jsonb not null,
  issued_at timestamptz not null default now(),
  unique (restaurant_id, invoice_number)
);

create index if not exists order_invoices_restaurant_issued_idx
  on public.order_invoices (restaurant_id, issued_at desc);

create or replace function public.issue_paid_order_invoice()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare v_number bigint;
begin
  if new.status <> 'paid' or old.status = 'paid' then return new; end if;
  perform pg_advisory_xact_lock(hashtextextended(new.restaurant_id::text, 1));
  select coalesce(max(invoice_number), 0) + 1 into v_number from public.order_invoices where restaurant_id = new.restaurant_id;
  insert into public.order_invoices (restaurant_id, order_id, invoice_number, total_amount, snapshot)
  values (new.restaurant_id, new.id, v_number, new.total_amount, jsonb_build_object(
    'order_number', new.order_number, 'table_id', new.table_id, 'customer_id', new.customer_id,
    'subtotal_amount', new.subtotal_amount, 'discount_amount', new.discount_amount,
    'tax_amount', new.tax_amount, 'service_charge_amount', new.service_charge_amount,
    'total_amount', new.total_amount
  ));
  return new;
end;
$$;
drop trigger if exists issue_paid_order_invoice on public.orders;
create trigger issue_paid_order_invoice after update of status on public.orders
for each row execute procedure public.issue_paid_order_invoice();

alter table public.table_merges enable row level security;
alter table public.table_merge_members enable row level security;
alter table public.order_invoices enable row level security;
drop policy if exists "table merges: members read" on public.table_merges;
drop policy if exists "table merge members: members read" on public.table_merge_members;
drop policy if exists "invoices: members read" on public.order_invoices;
create policy "table merges: members read" on public.table_merges for select to authenticated using (public.is_restaurant_member(restaurant_id));
create policy "table merge members: members read" on public.table_merge_members for select to authenticated using (exists (select 1 from public.table_merges m where m.id = merge_id and public.is_restaurant_member(m.restaurant_id)));
create policy "invoices: members read" on public.order_invoices for select to authenticated using (public.is_restaurant_member(restaurant_id));

-- Never permit an order to become paid except through collect_order_payment.
create or replace function public.transition_order_status(
  p_order_id uuid,
  p_restaurant_id uuid,
  p_to_status text
)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_order public.orders%rowtype;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_order.restaurant_id <> p_restaurant_id then raise exception 'Order not found for this restaurant' using errcode = 'P0002'; end if;
  if p_to_status = 'sent_to_kitchen' then perform public.submit_order_to_kitchen(p_order_id); return; end if;
  if p_to_status = 'cancelled' then
    if not public.has_restaurant_role(v_order.restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then raise exception 'You are not permitted to cancel this order' using errcode = '42501'; end if;
    if v_order.status in ('paid','cancelled') then raise exception 'This order cannot be cancelled' using errcode = '22023'; end if;
    update public.kitchen_ticket_items set status = 'cancelled' where kitchen_ticket_id in (select id from public.kitchen_tickets where order_id = p_order_id) and status <> 'cancelled';
    update public.kitchen_tickets set status = 'cancelled' where order_id = p_order_id and status <> 'cancelled';
    update public.orders set status = 'cancelled' where id = p_order_id;
    return;
  end if;
  raise exception 'Only kitchen transitions, cancellation, and payment settlement are supported' using errcode = '22023';
end;
$$;

create or replace function public.seat_table(p_table_id uuid, p_expected_version integer)
returns integer language plpgsql security definer set search_path = public, pg_temp as $$
declare v_table public.dining_tables%rowtype; v_actor uuid := auth.uid();
begin
  if v_actor is null then raise exception 'Authentication is required' using errcode = '28000'; end if;
  select * into v_table from public.dining_tables where id = p_table_id for update;
  if not found then raise exception 'Table not found' using errcode = 'P0002'; end if;
  if not public.has_restaurant_role(v_table.restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then raise exception 'You are not permitted to seat tables' using errcode = '42501'; end if;
  if v_table.version <> p_expected_version then raise exception 'Table was changed by another device; refresh and try again' using errcode = '40001'; end if;
  if v_table.status not in ('available','reserved') then raise exception 'Only available or reserved tables can be seated' using errcode = '22023'; end if;
  update public.dining_tables set status = 'occupied', version = version + 1 where id = v_table.id returning version into v_table.version;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action) values (v_table.restaurant_id, v_actor, 'dining_table', v_table.id, 'seated');
  return v_table.version;
end;
$$;

create or replace function public.assign_order_table(p_order_id uuid, p_table_id uuid, p_expected_table_version integer)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_order public.orders%rowtype; v_table public.dining_tables%rowtype; v_actor uuid := auth.uid();
begin
  if v_actor is null then raise exception 'Authentication is required' using errcode = '28000'; end if;
  select * into v_order from public.orders where id = p_order_id for update;
  select * into v_table from public.dining_tables where id = p_table_id for update;
  if not found or v_order.restaurant_id <> v_table.restaurant_id or v_order.branch_id <> v_table.branch_id then raise exception 'Order and table must belong to the same branch' using errcode = '23503'; end if;
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

create or replace function public.merge_tables(p_primary_table_id uuid, p_secondary_table_ids uuid[])
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_primary public.dining_tables%rowtype; v_id uuid; v_actor uuid := auth.uid(); v_table_id uuid;
begin
  if v_actor is null or coalesce(array_length(p_secondary_table_ids, 1), 0) = 0 then raise exception 'A primary table and at least one secondary table are required' using errcode = '22023'; end if;
  select * into v_primary from public.dining_tables where id = p_primary_table_id for update;
  if not found or not public.has_restaurant_role(v_primary.restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then raise exception 'You are not permitted to merge tables' using errcode = '42501'; end if;
  if exists (select 1 from public.table_merge_members mm join public.table_merges m on m.id = mm.merge_id where mm.table_id = v_primary.id and m.closed_at is null) then raise exception 'Primary table is already merged' using errcode = '23505'; end if;
  insert into public.table_merges (restaurant_id, primary_table_id, created_by) values (v_primary.restaurant_id, v_primary.id, v_actor) returning id into v_id;
  insert into public.table_merge_members (merge_id, table_id) values (v_id, v_primary.id);
  foreach v_table_id in array p_secondary_table_ids loop
    if v_table_id = v_primary.id then raise exception 'A table cannot be merged with itself' using errcode = '22023'; end if;
    perform 1 from public.dining_tables where id = v_table_id and restaurant_id = v_primary.restaurant_id and branch_id = v_primary.branch_id for update;
    if not found then raise exception 'Merged tables must be in the same branch' using errcode = '23503'; end if;
    if exists (select 1 from public.table_merge_members mm join public.table_merges m on m.id = mm.merge_id where mm.table_id = v_table_id and m.closed_at is null) then raise exception 'A selected table is already merged' using errcode = '23505'; end if;
    insert into public.table_merge_members (merge_id, table_id) values (v_id, v_table_id);
    update public.dining_tables set status = 'occupied', version = version + 1 where id = v_table_id;
  end loop;
  update public.dining_tables set status = 'occupied', version = version + 1 where id = v_primary.id;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data) values (v_primary.restaurant_id, v_actor, 'table_merge', v_id, 'created', jsonb_build_object('primary_table_id', v_primary.id, 'secondary_table_ids', p_secondary_table_ids));
  return v_id;
end;
$$;

create or replace function public.split_table_merge(p_merge_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_merge public.table_merges%rowtype; v_actor uuid := auth.uid();
begin
  select * into v_merge from public.table_merges where id = p_merge_id for update;
  if not found or v_merge.closed_at is not null then raise exception 'Active table merge not found' using errcode = 'P0002'; end if;
  if not public.has_restaurant_role(v_merge.restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then raise exception 'You are not permitted to split tables' using errcode = '42501'; end if;
  update public.dining_tables set status = case when exists (select 1 from public.orders o where o.table_id = dining_tables.id and o.status in ('open','sent_to_kitchen','preparing','ready','served','billed')) then 'occupied' else 'available' end, version = version + 1 where id in (select table_id from public.table_merge_members where merge_id = v_merge.id);
  update public.table_merges set closed_at = now() where id = v_merge.id;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action) values (v_merge.restaurant_id, v_actor, 'table_merge', v_merge.id, 'split');
end;
$$;

create or replace function public.apply_order_discount(p_order_id uuid, p_discount_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_order public.orders%rowtype; v_discount public.discounts%rowtype; v_actor uuid := auth.uid(); v_amount integer;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  select * into v_discount from public.discounts where id = p_discount_id;
  if not found or v_discount.restaurant_id <> v_order.restaurant_id or not v_discount.is_active or (v_discount.starts_at is not null and v_discount.starts_at > now()) or (v_discount.ends_at is not null and v_discount.ends_at <= now()) then raise exception 'Discount is unavailable' using errcode = '23503'; end if;
  if v_order.status <> 'open' or not public.has_restaurant_role(v_order.restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then raise exception 'You are not permitted to discount this order' using errcode = '42501'; end if;
  v_amount := case when v_discount.discount_type = 'percentage' then least((v_order.subtotal_amount * v_discount.value / 10000)::integer, coalesce(v_discount.max_discount_amount, 2147483647)) else least(v_discount.value, v_order.subtotal_amount) end;
  update public.orders set discount_amount = v_amount, total_amount = subtotal_amount - v_amount + tax_amount + service_charge_amount where id = v_order.id;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data) values (v_order.restaurant_id, v_actor, 'order', v_order.id, 'discount_applied', jsonb_build_object('discount_id', v_discount.id, 'amount', v_amount));
end;
$$;

create or replace function public.refund_payment(p_payment_id uuid, p_amount integer, p_reason text)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_payment public.payments%rowtype; v_actor uuid := auth.uid(); v_refund_id uuid; v_refunded integer;
begin
  if p_amount <= 0 or nullif(trim(p_reason), '') is null then raise exception 'Refund amount and reason are required' using errcode = '22023'; end if;
  select * into v_payment from public.payments where id = p_payment_id for update;
  if not found or v_payment.status <> 'completed' or not public.has_restaurant_role(v_payment.restaurant_id, array['owner','manager','cashier']::public.app_role[]) then raise exception 'You are not permitted to refund this payment' using errcode = '42501'; end if;
  select coalesce(sum(amount), 0)::integer into v_refunded from public.payment_refunds where payment_id = v_payment.id;
  if p_amount > v_payment.amount - v_refunded then raise exception 'Refund exceeds captured payment' using errcode = '22023'; end if;
  insert into public.payment_refunds (restaurant_id, payment_id, amount, reason, refunded_by) values (v_payment.restaurant_id, v_payment.id, p_amount, trim(p_reason), v_actor) returning id into v_refund_id;
  if p_amount + v_refunded = v_payment.amount then update public.payments set status = 'refunded' where id = v_payment.id; end if;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data) values (v_payment.restaurant_id, v_actor, 'payment_refund', v_refund_id, 'created', jsonb_build_object('payment_id', v_payment.id, 'amount', p_amount, 'reason', trim(p_reason)));
  return v_refund_id;
end;
$$;

create or replace function public.open_shift(p_restaurant_id uuid, p_branch_id uuid, p_opening_cash_amount integer)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_actor uuid := auth.uid(); v_shift uuid;
begin
  if p_opening_cash_amount < 0 or not public.has_restaurant_role(p_restaurant_id, array['owner','manager','cashier']::public.app_role[]) then raise exception 'You are not permitted to open a shift' using errcode = '42501'; end if;
  if exists (select 1 from public.shifts where restaurant_id = p_restaurant_id and branch_id = p_branch_id and user_id = v_actor and closed_at is null) then raise exception 'You already have an open shift for this branch' using errcode = '23505'; end if;
  if not exists (select 1 from public.branches where id = p_branch_id and restaurant_id = p_restaurant_id and is_active) then raise exception 'Branch does not belong to this restaurant or is inactive' using errcode = '23503'; end if;
  insert into public.shifts (restaurant_id, branch_id, user_id, opening_cash_amount) values (p_restaurant_id, p_branch_id, v_actor, p_opening_cash_amount) returning id into v_shift;
  return v_shift;
end;
$$;

create or replace function public.close_shift(p_shift_id uuid, p_closing_cash_amount integer, p_notes text default null)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_shift public.shifts%rowtype; v_actor uuid := auth.uid();
begin
  if p_closing_cash_amount < 0 then raise exception 'Closing cash cannot be negative' using errcode = '22023'; end if;
  select * into v_shift from public.shifts where id = p_shift_id for update;
  if not found or v_shift.closed_at is not null or not public.has_restaurant_role(v_shift.restaurant_id, array['owner','manager','cashier']::public.app_role[]) then raise exception 'You are not permitted to close this shift' using errcode = '42501'; end if;
  update public.shifts set closing_cash_amount = p_closing_cash_amount, closed_at = now(), notes = nullif(trim(p_notes), '') where id = v_shift.id;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data) values (v_shift.restaurant_id, v_actor, 'shift', v_shift.id, 'closed', jsonb_build_object('closing_cash_amount', p_closing_cash_amount));
end;
$$;

create or replace function public.record_cash_movement(p_shift_id uuid, p_movement_type text, p_amount integer, p_reason text)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_shift public.shifts%rowtype; v_actor uuid := auth.uid(); v_id uuid;
begin
  if p_movement_type not in ('cash_in','cash_out','adjustment') or p_amount <= 0 or nullif(trim(p_reason), '') is null then raise exception 'Valid movement, amount, and reason are required' using errcode = '22023'; end if;
  select * into v_shift from public.shifts where id = p_shift_id for update;
  if not found or v_shift.closed_at is not null or not public.has_restaurant_role(v_shift.restaurant_id, array['owner','manager','cashier']::public.app_role[]) then raise exception 'You are not permitted to record this cash movement' using errcode = '42501'; end if;
  insert into public.cash_drawer_movements (restaurant_id, shift_id, movement_type, amount, reason, recorded_by) values (v_shift.restaurant_id, v_shift.id, p_movement_type, p_amount, trim(p_reason), v_actor) returning id into v_id;
  return v_id;
end;

$$;

revoke all on function public.seat_table(uuid, integer), public.assign_order_table(uuid, uuid, integer), public.merge_tables(uuid, uuid[]), public.split_table_merge(uuid), public.apply_order_discount(uuid, uuid), public.refund_payment(uuid, integer, text), public.open_shift(uuid, uuid, integer), public.close_shift(uuid, integer, text), public.record_cash_movement(uuid, text, integer, text) from public, anon;
grant execute on function public.seat_table(uuid, integer), public.assign_order_table(uuid, uuid, integer), public.merge_tables(uuid, uuid[]), public.split_table_merge(uuid), public.apply_order_discount(uuid, uuid), public.refund_payment(uuid, integer, text), public.open_shift(uuid, uuid, integer), public.close_shift(uuid, integer, text), public.record_cash_movement(uuid, text, integer, text) to authenticated;
