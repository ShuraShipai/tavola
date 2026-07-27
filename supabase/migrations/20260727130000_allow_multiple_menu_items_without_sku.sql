-- SKU is optional for menu items. Standard PostgreSQL unique constraints allow
-- multiple NULL values; the original `unique nulls not distinct` constraint
-- incorrectly allowed only one menu item with no SKU per restaurant.
alter table public.menu_items
  drop constraint if exists menu_items_restaurant_id_sku_key;

alter table public.menu_items
  add constraint menu_items_restaurant_id_sku_key unique (restaurant_id, sku);
