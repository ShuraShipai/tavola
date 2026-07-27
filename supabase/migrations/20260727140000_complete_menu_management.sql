-- Complete the fields represented by the Menu design screens. Existing fields
-- already model availability and display order, so this migration only adds
-- attributes that were genuinely absent from the original schema.
alter table public.menu_categories
  add column if not exists description text;

alter table public.menu_items
  add column if not exists food_type text,
  add column if not exists tracks_stock boolean not null default false,
  add column if not exists is_chef_recommended boolean not null default false;

-- Earlier category creation used the schema default (zero) for every row.
-- Repair existing data into the one-based, deterministic order shown to staff.
with ordered_categories as (
  select id,
         row_number() over (
           partition by restaurant_id
           order by sort_order, created_at, id
         ) as new_sort_order
  from public.menu_categories
)
update public.menu_categories category
set sort_order = ordered_categories.new_sort_order
from ordered_categories
where category.id = ordered_categories.id
  and category.sort_order is distinct from ordered_categories.new_sort_order;

-- A category must belong to the same restaurant as every item assigned to it.
-- This prevents an otherwise-valid foreign key from crossing tenant boundaries.
create or replace function public.validate_menu_item_tenant()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_category_restaurant_id uuid;
begin
  if tg_op = 'UPDATE'
     and new.restaurant_id is distinct from old.restaurant_id then
    raise exception 'Menu items cannot be transferred between restaurants'
      using errcode = '42501';
  end if;

  if new.category_id is not null then
    select restaurant_id into v_category_restaurant_id
    from public.menu_categories
    where id = new.category_id;

    if v_category_restaurant_id is null
       or v_category_restaurant_id <> new.restaurant_id then
      raise exception 'Menu item category must belong to the same restaurant'
        using errcode = '23503';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists menu_items_validate_tenant on public.menu_items;
create trigger menu_items_validate_tenant
before insert or update on public.menu_items
for each row execute function public.validate_menu_item_tenant();

-- Category deletion is a single server-authoritative operation: it locks the
-- category, verifies the JWT actor's role, reassigns current menu items, and
-- then deletes the category. Historical order rows remain untouched.
create or replace function public.delete_menu_category(
  p_category_id uuid,
  p_destination_category_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_category public.menu_categories%rowtype;
  v_destination_restaurant_id uuid;
begin
  select * into v_category
  from public.menu_categories
  where id = p_category_id
  for update;

  if not found then
    raise exception 'Menu category was not found' using errcode = 'P0002';
  end if;

  if not public.has_restaurant_role(
    v_category.restaurant_id,
    array['owner', 'manager']::public.app_role[]
  ) then
    raise exception 'Only an owner or manager can delete a menu category'
      using errcode = '42501';
  end if;

  if p_destination_category_id = p_category_id then
    raise exception 'Choose a different destination category'
      using errcode = '22023';
  end if;

  if p_destination_category_id is not null then
    select restaurant_id into v_destination_restaurant_id
    from public.menu_categories
    where id = p_destination_category_id;
    if v_destination_restaurant_id is null
       or v_destination_restaurant_id <> v_category.restaurant_id then
      raise exception 'Destination category must belong to the same restaurant'
        using errcode = '23503';
    end if;
  end if;

  update public.menu_items
  set category_id = p_destination_category_id,
      updated_at = now()
  where category_id = v_category.id;

  delete from public.menu_categories where id = v_category.id;
end;
$$;

revoke all on function public.delete_menu_category(uuid, uuid) from public;
grant execute on function public.delete_menu_category(uuid, uuid) to authenticated;
