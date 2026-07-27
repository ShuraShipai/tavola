-- Phase 0: make state changes explicit for operational entities.
-- All transitions are validated server-side; clients cannot jump between states.

create or replace function public.validate_dining_table_status_transition()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.restaurant_id <> old.restaurant_id then
    raise exception 'Dining table tenant cannot change' using errcode = '23514';
  end if;
  if new.status <> old.status and not (
    (old.status = 'available' and new.status in ('occupied', 'reserved', 'unavailable')) or
    (old.status = 'occupied' and new.status in ('available', 'reserved')) or
    (old.status = 'reserved' and new.status in ('available', 'occupied')) or
    (old.status = 'unavailable' and new.status = 'available')
  ) then
    raise exception 'Invalid dining table status transition from % to %', old.status, new.status
      using errcode = '22023';
  end if;
  return new;
end;
$$;

drop trigger if exists dining_tables_validate_status on public.dining_tables;
create trigger dining_tables_validate_status
before update of status, restaurant_id on public.dining_tables
for each row execute procedure public.validate_dining_table_status_transition();

create or replace function public.validate_reservation_status_transition()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.restaurant_id <> old.restaurant_id then
    raise exception 'Reservation tenant cannot change' using errcode = '23514';
  end if;
  if new.status <> old.status and not (
    (old.status = 'pending' and new.status in ('confirmed', 'cancelled')) or
    (old.status = 'confirmed' and new.status in ('seated', 'cancelled', 'no_show')) or
    (old.status = 'seated' and new.status = 'completed') or
    (old.status in ('completed', 'cancelled', 'no_show') and new.status = old.status)
  ) then
    raise exception 'Invalid reservation status transition from % to %', old.status, new.status
      using errcode = '22023';
  end if;
  return new;
end;
$$;

drop trigger if exists reservations_validate_status on public.reservations;
create trigger reservations_validate_status
before update of status, restaurant_id on public.reservations
for each row execute procedure public.validate_reservation_status_transition();

