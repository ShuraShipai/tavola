-- Repair projects created before the restaurant-assets Storage bucket was
-- provisioned. This migration is idempotent and does not alter stored files.
insert into storage.buckets (id, name, public)
values ('restaurant-assets', 'restaurant-assets', false)
on conflict (id) do update set public = false;

drop policy if exists "restaurant assets: members read" on storage.objects;
drop policy if exists "restaurant assets: managers write" on storage.objects;
drop policy if exists "restaurant assets: managers update" on storage.objects;
drop policy if exists "restaurant assets: managers delete" on storage.objects;

create policy "restaurant assets: members read" on storage.objects
for select to authenticated using (
  bucket_id = 'restaurant-assets'
  and public.is_restaurant_member(
    nullif((storage.foldername(name))[1], '')::uuid
  )
);

create policy "restaurant assets: managers write" on storage.objects
for insert to authenticated with check (
  bucket_id = 'restaurant-assets'
  and public.has_restaurant_role(
    nullif((storage.foldername(name))[1], '')::uuid,
    array['owner', 'manager']::public.app_role[]
  )
);

create policy "restaurant assets: managers update" on storage.objects
for update to authenticated using (
  bucket_id = 'restaurant-assets'
  and public.has_restaurant_role(
    nullif((storage.foldername(name))[1], '')::uuid,
    array['owner', 'manager']::public.app_role[]
  )
) with check (
  bucket_id = 'restaurant-assets'
  and public.has_restaurant_role(
    nullif((storage.foldername(name))[1], '')::uuid,
    array['owner', 'manager']::public.app_role[]
  )
);

create policy "restaurant assets: managers delete" on storage.objects
for delete to authenticated using (
  bucket_id = 'restaurant-assets'
  and public.has_restaurant_role(
    nullif((storage.foldername(name))[1], '')::uuid,
    array['owner', 'manager']::public.app_role[]
  )
);
