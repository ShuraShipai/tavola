-- Table editor: secure create, update and delete operations.
alter table public.dining_tables
  add column if not exists version integer not null default 1,
  add column if not exists current_status_detail text;

drop function if exists public.save_dining_table(uuid, uuid, text, integer, integer);
drop function if exists public.save_dining_table(uuid, uuid, uuid, text, integer, integer, text);

create function public.save_dining_table(
  p_restaurant_id uuid,
  p_table_id uuid default null,
  p_branch_id uuid default null,
  p_label text default null,
  p_capacity integer default null,
  p_sort_order integer default 0,
  p_current_status_detail text default null
)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_branch_id uuid;
  v_table_id uuid;
  v_existing public.dining_tables%rowtype;
begin
  if auth.uid() is null or not public.has_restaurant_role(p_restaurant_id, array['owner','manager']::public.app_role[]) then
    raise exception 'You are not permitted to save tables' using errcode = '42501';
  end if;
  if nullif(trim(coalesce(p_label, '')), '') is null or p_capacity not between 1 and 100 or p_sort_order < 0 then
    raise exception 'Table name, capacity, or number is invalid' using errcode = '22023';
  end if;
  if p_table_id is not null then
    select * into v_existing from public.dining_tables where id = p_table_id for update;
    if not found or v_existing.restaurant_id <> p_restaurant_id then
      raise exception 'Table not found' using errcode = 'P0002';
    end if;
  end if;
  v_branch_id := coalesce(p_branch_id, v_existing.branch_id);
  if v_branch_id is null then
    select id into v_branch_id from public.branches
    where restaurant_id = p_restaurant_id and is_active
    order by created_at, id limit 1;
  end if;
  if not exists (select 1 from public.branches where id = v_branch_id and restaurant_id = p_restaurant_id and is_active) then
    raise exception 'No active dining area is available' using errcode = '23503';
  end if;
  if p_table_id is null then
    insert into public.dining_tables (restaurant_id, branch_id, label, capacity, sort_order, status, version, current_status_detail)
    values (p_restaurant_id, v_branch_id, trim(p_label), p_capacity, p_sort_order, 'available', 1, nullif(trim(p_current_status_detail), ''))
    returning id into v_table_id;
  else
    update public.dining_tables
    set label = trim(p_label), capacity = p_capacity, sort_order = p_sort_order,
        current_status_detail = nullif(trim(p_current_status_detail), ''), updated_at = now()
    where id = p_table_id
    returning id into v_table_id;
  end if;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action)
  values (p_restaurant_id, auth.uid(), 'dining_table', v_table_id,
    case when p_table_id is null then 'created' else 'updated' end);
  return v_table_id;
end;
$$;

create or replace function public.delete_dining_table(p_table_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_table public.dining_tables%rowtype;
begin
  select * into v_table from public.dining_tables where id = p_table_id for update;
  if not found then raise exception 'Table not found' using errcode = 'P0002'; end if;
  if auth.uid() is null or not public.has_restaurant_role(v_table.restaurant_id, array['owner','manager']::public.app_role[]) then
    raise exception 'You are not permitted to delete tables' using errcode = '42501';
  end if;
  if exists (select 1 from public.orders where table_id = v_table.id and status in ('open','sent_to_kitchen','preparing','ready','served','billed'))
    or exists (select 1 from public.reservations where table_id = v_table.id and status in ('pending','confirmed','seated'))
    or exists (select 1 from public.table_merge_members mm join public.table_merges m on m.id = mm.merge_id where mm.table_id = v_table.id and m.closed_at is null) then
    raise exception 'Table is in active service, reserved, or merged' using errcode = '22023';
  end if;
  delete from public.dining_tables where id = v_table.id;
  insert into public.audit_logs (restaurant_id, actor_id, entity_type, entity_id, action)
  values (v_table.restaurant_id, auth.uid(), 'dining_table', v_table.id, 'deleted');
end;
$$;

revoke all on function public.save_dining_table(uuid, uuid, uuid, text, integer, integer, text), public.delete_dining_table(uuid) from public;
grant execute on function public.save_dining_table(uuid, uuid, uuid, text, integer, integer, text), public.delete_dining_table(uuid) to authenticated;
