-- Guest and service operations: tenant-safe relationships, explicit state
-- transitions, persisted notifications, and in-product support requests.

create table public.operational_notifications (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  recipient_user_id uuid references auth.users(id) on delete cascade,
  event_type text not null check (event_type in ('reservation', 'customer', 'order', 'inventory', 'system')),
  title text not null check (char_length(trim(title)) between 1 and 160),
  body text not null check (char_length(trim(body)) between 1 and 1000),
  entity_type text,
  entity_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index operational_notifications_recipient_idx on public.operational_notifications (recipient_user_id, created_at desc) where read_at is null;
create index operational_notifications_restaurant_idx on public.operational_notifications (restaurant_id, created_at desc);
alter table public.operational_notifications enable row level security;
create policy "notifications: recipients read" on public.operational_notifications for select to authenticated using (recipient_user_id = auth.uid() and public.is_restaurant_member(restaurant_id));
create policy "notifications: recipients update read state" on public.operational_notifications for update to authenticated using (recipient_user_id = auth.uid() and public.is_restaurant_member(restaurant_id)) with check (recipient_user_id = auth.uid() and public.is_restaurant_member(restaurant_id));

create table public.support_requests (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  subject text not null check (char_length(trim(subject)) between 3 and 160),
  message text not null check (char_length(trim(message)) between 1 and 4000),
  priority text not null default 'normal' check (priority in ('low', 'normal', 'high', 'urgent')),
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.support_requests enable row level security;
create policy "support: members create" on public.support_requests for insert to authenticated with check (created_by = auth.uid() and public.is_restaurant_member(restaurant_id));
create policy "support: requesters or managers read" on public.support_requests for select to authenticated using (created_by = auth.uid() or public.has_restaurant_role(restaurant_id, array['owner', 'manager']::public.app_role[]));

create or replace function public.associate_order_customer(p_order_id uuid, p_customer_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_order public.orders%rowtype; v_actor uuid := auth.uid();
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_actor is null or not public.has_restaurant_role(v_order.restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]) then raise exception 'Not permitted to associate this customer' using errcode = '42501'; end if;
  if not exists (select 1 from public.customers where id = p_customer_id and restaurant_id = v_order.restaurant_id) then raise exception 'Customer belongs to a different restaurant' using errcode = '23514'; end if;
  update public.orders set customer_id = p_customer_id, updated_at = now() where id = v_order.id;
end; $$;

create or replace function public.transition_reservation(p_reservation_id uuid, p_status public.reservation_status, p_table_id uuid default null)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_reservation public.reservations%rowtype; v_actor uuid := auth.uid();
begin
  select * into v_reservation from public.reservations where id = p_reservation_id for update;
  if not found or v_actor is null or not public.has_restaurant_role(v_reservation.restaurant_id, array['owner', 'manager', 'cashier', 'waiter']::public.app_role[]) then raise exception 'Not permitted to update this reservation' using errcode = '42501'; end if;
  if p_table_id is not null and not exists (select 1 from public.dining_tables where id = p_table_id and restaurant_id = v_reservation.restaurant_id and branch_id = v_reservation.branch_id) then raise exception 'Table belongs to a different branch or restaurant' using errcode = '23514'; end if;
  if p_status = 'seated' and coalesce(p_table_id, v_reservation.table_id) is null then raise exception 'A table is required to seat guests' using errcode = '22023'; end if;
  update public.reservations set status = p_status, table_id = coalesce(p_table_id, table_id), updated_at = now() where id = v_reservation.id;
  if p_status = 'seated' then update public.dining_tables set status = 'occupied' where id = coalesce(p_table_id, v_reservation.table_id); end if;
  if p_status in ('cancelled', 'no_show', 'completed') and v_reservation.table_id is not null then update public.dining_tables set status = 'available' where id = v_reservation.table_id and status in ('reserved', 'occupied'); end if;
end; $$;

create or replace function public.mark_notification_read(p_notification_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin update public.operational_notifications set read_at = coalesce(read_at, now()) where id = p_notification_id and recipient_user_id = auth.uid(); end; $$;

alter publication supabase_realtime add table public.operational_notifications;
revoke all on function public.associate_order_customer(uuid, uuid), public.transition_reservation(uuid, public.reservation_status, uuid), public.mark_notification_read(uuid) from public;
grant execute on function public.associate_order_customer(uuid, uuid), public.transition_reservation(uuid, public.reservation_status, uuid), public.mark_notification_read(uuid) to authenticated;
