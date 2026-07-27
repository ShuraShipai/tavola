-- Every restaurant must have an active branch before orders can be created.
-- Provision one automatically for new and existing restaurants.

-- Backfill restaurants that have no active branch. If an inactive branch exists,
-- reactivate it rather than creating a duplicate branch name.
update public.branches branch
set is_active = true, updated_at = now()
where branch.id in (
  select distinct on (restaurant.id) branch_to_activate.id
  from public.restaurants restaurant
  join public.branches branch_to_activate
    on branch_to_activate.restaurant_id = restaurant.id
  where not exists (
    select 1 from public.branches active_branch
    where active_branch.restaurant_id = restaurant.id
      and active_branch.is_active
  )
  order by restaurant.id, branch_to_activate.created_at asc
);

insert into public.branches (restaurant_id, name)
select restaurant.id, 'Main Branch'
from public.restaurants restaurant
where not exists (
  select 1
  from public.branches branch
  where branch.restaurant_id = restaurant.id
);

create or replace function public.provision_default_branch()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- A restaurant must always have one usable branch for order creation.
  update public.branches
  set is_active = true, updated_at = now()
  where id = (
    select branch.id
    from public.branches branch
    where branch.restaurant_id = new.id
    order by branch.created_at asc
    limit 1
  );

  insert into public.branches (restaurant_id, name)
  values (new.id, 'Main Branch')
  on conflict (restaurant_id, name) do nothing;
  return new;
end;
$$;

drop trigger if exists restaurants_provision_default_branch on public.restaurants;
create trigger restaurants_provision_default_branch
after insert on public.restaurants
for each row execute procedure public.provision_default_branch();

revoke all on function public.provision_default_branch() from public, anon, authenticated;
