-- Reservation creation, assignment and seating are server-authoritative. The
-- actor comes from auth.uid(); clients may never supply created_by or bypass
-- restaurant/branch/capacity checks.

create index if not exists reservations_table_schedule_idx
  on public.reservations (table_id, reserved_for)
  where status in ('pending', 'confirmed', 'seated');

alter table public.reservations
  add column if not exists send_confirmation_sms boolean not null default true;

create or replace function public.list_reservation_eligible_tables(
  p_restaurant_id uuid,
  p_branch_id uuid,
  p_reserved_for timestamptz,
  p_party_size integer,
  p_duration_minutes integer default 90,
  p_exclude_reservation_id uuid default null
)
returns table (id uuid, label text, capacity integer)
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if auth.uid() is null or not public.has_restaurant_role(p_restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then
    raise exception 'You are not permitted to view eligible tables' using errcode = '42501';
  end if;
  if p_party_size not between 1 and 100 or p_duration_minutes not between 15 and 720 then
    raise exception 'Party size or duration is invalid' using errcode = '22023';
  end if;
  return query
  select t.id, t.label, t.capacity
  from public.dining_tables t
  where t.restaurant_id = p_restaurant_id
    and t.branch_id = p_branch_id
    and t.capacity >= p_party_size
    and t.status <> 'unavailable'
    and not exists (
      select 1 from public.reservations r
      where r.table_id = t.id
        and r.id is distinct from p_exclude_reservation_id
        and r.status in ('pending', 'confirmed', 'seated')
        and r.reserved_for < p_reserved_for + make_interval(mins => p_duration_minutes)
        and r.reserved_for + make_interval(mins => r.duration_minutes) > p_reserved_for
    )
  order by t.capacity, t.sort_order, t.label;
end;
$$;

create or replace function public.assign_reservation_table(
  p_reservation_id uuid,
  p_table_id uuid
)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_reservation public.reservations%rowtype; v_table public.dining_tables%rowtype;
begin
  select * into v_reservation from public.reservations where id = p_reservation_id for update;
  if not found then raise exception 'Reservation not found' using errcode = 'P0002'; end if;
  if auth.uid() is null or not public.has_restaurant_role(v_reservation.restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then
    raise exception 'You are not permitted to assign reservation tables' using errcode = '42501';
  end if;
  if v_reservation.status not in ('pending','confirmed') then
    raise exception 'Only pending or confirmed reservations can be assigned a table' using errcode = '22023';
  end if;
  select * into v_table from public.dining_tables where id = p_table_id for update;
  if not found or v_table.restaurant_id <> v_reservation.restaurant_id or v_table.branch_id <> v_reservation.branch_id then
    raise exception 'Table must belong to the reservation branch' using errcode = '23503';
  end if;
  if v_table.status = 'unavailable' or v_table.capacity < v_reservation.party_size then
    raise exception 'Table cannot seat this reservation' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.reservations r
    where r.table_id = v_table.id and r.id <> v_reservation.id
      and r.status in ('pending','confirmed','seated')
      and r.reserved_for < v_reservation.reserved_for + make_interval(mins => v_reservation.duration_minutes)
      and r.reserved_for + make_interval(mins => r.duration_minutes) > v_reservation.reserved_for
  ) then raise exception 'Table already has an overlapping reservation' using errcode = '23505'; end if;
  update public.reservations set table_id = v_table.id, updated_at = now() where id = v_reservation.id;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data)
  values (v_reservation.restaurant_id, auth.uid(), 'reservation', v_reservation.id, 'table_assigned', jsonb_build_object('table_id', v_table.id));
end;
$$;

create or replace function public.save_reservation(
  p_reservation_id uuid default null,
  p_restaurant_id uuid default null,
  p_branch_id uuid default null,
  p_customer_id uuid default null,
  p_table_id uuid default null,
  p_guest_name text default null,
  p_guest_phone text default null,
  p_party_size integer default null,
  p_reserved_for timestamptz default null,
  p_duration_minutes integer default 90,
  p_notes text default null,
  p_send_confirmation_sms boolean default true
)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_id uuid; v_existing public.reservations%rowtype;
begin
  if auth.uid() is null or not public.has_restaurant_role(p_restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then
    raise exception 'You are not permitted to save reservations' using errcode = '42501';
  end if;
  if nullif(trim(coalesce(p_guest_name, '')), '') is null or p_party_size not between 1 and 100 or p_reserved_for is null or p_duration_minutes not between 15 and 720 then
    raise exception 'Guest name, party size, reservation time, or duration is invalid' using errcode = '22023';
  end if;
  -- A reservation need not be assigned a table. When callers omit a branch,
  -- choose the restaurant's first active branch rather than creating an
  -- unusable row or trusting a client-side fallback.
  if p_branch_id is null then
    select id into p_branch_id from public.branches
    where restaurant_id = p_restaurant_id and is_active
    order by created_at, id limit 1;
  end if;
  if not exists (select 1 from public.branches where id = p_branch_id and restaurant_id = p_restaurant_id and is_active) then
    raise exception 'Reservation branch is invalid or inactive' using errcode = '23503';
  end if;
  if p_customer_id is not null and not exists (select 1 from public.customers where id = p_customer_id and restaurant_id = p_restaurant_id) then
    raise exception 'Customer belongs to another restaurant' using errcode = '23503';
  end if;
  if p_reservation_id is null then
    insert into public.reservations (restaurant_id, branch_id, customer_id, guest_name, guest_phone, party_size, reserved_for, duration_minutes, notes, send_confirmation_sms, created_by)
    values (p_restaurant_id, p_branch_id, p_customer_id, trim(p_guest_name), nullif(trim(p_guest_phone), ''), p_party_size, p_reserved_for, p_duration_minutes, nullif(trim(p_notes), ''), coalesce(p_send_confirmation_sms, true), auth.uid())
    returning id into v_id;
  else
    select * into v_existing from public.reservations where id = p_reservation_id for update;
    if not found or v_existing.restaurant_id <> p_restaurant_id then raise exception 'Reservation not found' using errcode = 'P0002'; end if;
    if v_existing.status not in ('pending','confirmed') then raise exception 'Only pending or confirmed reservations can be edited' using errcode = '22023'; end if;
    update public.reservations set branch_id = p_branch_id, customer_id = p_customer_id, guest_name = trim(p_guest_name), guest_phone = nullif(trim(p_guest_phone), ''), party_size = p_party_size, reserved_for = p_reserved_for, duration_minutes = p_duration_minutes, notes = nullif(trim(p_notes), ''), send_confirmation_sms = coalesce(p_send_confirmation_sms, true), table_id = null, updated_at = now() where id = p_reservation_id;
    v_id := p_reservation_id;
  end if;
  if p_table_id is not null then perform public.assign_reservation_table(v_id, p_table_id); end if;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action)
  values (p_restaurant_id, auth.uid(), 'reservation', v_id, case when p_reservation_id is null then 'created' else 'updated' end);
  return v_id;
end;
$$;

create or replace function public.seat_reservation(p_reservation_id uuid, p_table_id uuid default null)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_reservation public.reservations%rowtype; v_table public.dining_tables%rowtype; v_target_table_id uuid;
begin
  select * into v_reservation from public.reservations where id = p_reservation_id for update;
  if not found then raise exception 'Reservation not found' using errcode = 'P0002'; end if;
  if auth.uid() is null or not public.has_restaurant_role(v_reservation.restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then raise exception 'You are not permitted to seat reservations' using errcode = '42501'; end if;
  if v_reservation.status = 'pending' then
    update public.reservations set status = 'confirmed', updated_at = now() where id = v_reservation.id;
    select * into v_reservation from public.reservations where id = v_reservation.id for update;
  end if;
  if v_reservation.status <> 'confirmed' then raise exception 'Only confirmed reservations can be seated' using errcode = '22023'; end if;
  v_target_table_id := coalesce(p_table_id, v_reservation.table_id);
  if v_target_table_id is null then raise exception 'A table is required to seat guests' using errcode = '22023'; end if;
  if p_table_id is not null and p_table_id <> v_reservation.table_id then perform public.assign_reservation_table(v_reservation.id, p_table_id); end if;
  select * into v_table from public.dining_tables where id = v_target_table_id for update;
  if not found or v_table.restaurant_id <> v_reservation.restaurant_id or v_table.branch_id <> v_reservation.branch_id or v_table.capacity < v_reservation.party_size or v_table.status not in ('available','reserved') then
    raise exception 'Selected table is no longer eligible for seating' using errcode = '22023';
  end if;
  update public.dining_tables set status = 'occupied', version = version + 1, updated_at = now() where id = v_table.id;
  update public.reservations set table_id = v_table.id, status = 'seated', updated_at = now() where id = v_reservation.id;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data)
  values (v_reservation.restaurant_id, auth.uid(), 'reservation', v_reservation.id, 'seated', jsonb_build_object('table_id', v_table.id));
end;
$$;

create or replace function public.cancel_reservation(p_reservation_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_reservation public.reservations%rowtype;
begin
  select * into v_reservation from public.reservations where id = p_reservation_id for update;
  if not found then raise exception 'Reservation not found' using errcode = 'P0002'; end if;
  if auth.uid() is null or not public.has_restaurant_role(v_reservation.restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then raise exception 'You are not permitted to cancel reservations' using errcode = '42501'; end if;
  if v_reservation.status not in ('pending','confirmed') then raise exception 'Only pending or confirmed reservations can be cancelled' using errcode = '22023'; end if;
  update public.reservations set status = 'cancelled', updated_at = now() where id = v_reservation.id;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action) values (v_reservation.restaurant_id, auth.uid(), 'reservation', v_reservation.id, 'cancelled');
end;
$$;

-- Retain the legacy RPC name for older clients, but route its sensitive paths
-- through the locked assignment/seating/cancellation operations above.
create or replace function public.transition_reservation(
  p_reservation_id uuid,
  p_status public.reservation_status,
  p_table_id uuid default null
)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_reservation public.reservations%rowtype;
begin
  select * into v_reservation from public.reservations where id = p_reservation_id for update;
  if not found then raise exception 'Reservation not found' using errcode = 'P0002'; end if;
  if auth.uid() is null or not public.has_restaurant_role(v_reservation.restaurant_id, array['owner','manager','cashier','waiter']::public.app_role[]) then
    raise exception 'You are not permitted to update this reservation' using errcode = '42501';
  end if;
  if p_status = 'seated' then
    perform public.seat_reservation(p_reservation_id, p_table_id);
    return;
  end if;
  if p_status = 'cancelled' then
    perform public.cancel_reservation(p_reservation_id);
    return;
  end if;
  if p_table_id is not null then perform public.assign_reservation_table(p_reservation_id, p_table_id); end if;
  update public.reservations set status = p_status, updated_at = now() where id = p_reservation_id;
  if p_status in ('completed', 'no_show') and v_reservation.table_id is not null
    and not exists (select 1 from public.orders o where o.table_id = v_reservation.table_id and o.status in ('open','sent_to_kitchen','preparing','ready','served','billed')) then
    update public.dining_tables set status = 'available', version = version + 1, updated_at = now()
    where id = v_reservation.table_id and status in ('reserved','occupied');
  end if;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action, after_data)
  values (v_reservation.restaurant_id, auth.uid(), 'reservation', p_reservation_id, 'status_changed', jsonb_build_object('status', p_status));
end;
$$;

revoke all on function public.list_reservation_eligible_tables(uuid, uuid, timestamptz, integer, integer, uuid), public.assign_reservation_table(uuid, uuid), public.save_reservation(uuid, uuid, uuid, uuid, uuid, text, text, integer, timestamptz, integer, text, boolean), public.seat_reservation(uuid, uuid), public.cancel_reservation(uuid) from public;
grant execute on function public.list_reservation_eligible_tables(uuid, uuid, timestamptz, integer, integer, uuid), public.assign_reservation_table(uuid, uuid), public.save_reservation(uuid, uuid, uuid, uuid, uuid, text, text, integer, timestamptz, integer, text, boolean), public.seat_reservation(uuid, uuid), public.cancel_reservation(uuid) to authenticated;
