# Tavola Supabase database

The initial Tavola database schema is in `migrations/20260724173000_initial_tavola_schema.sql`.
It creates the multi-tenant restaurant POS tables, RLS policies, audit triggers,
Realtime publications, and the private `restaurant-assets` storage bucket.

## Apply the migration

Authenticate the Supabase CLI with an account that owns the Tavola project, then
link and push the migration:

```bash
npx supabase login
npx supabase link --project-ref kxudwhbrcsqccclwmhla
npx supabase db push
```

The Flutter publishable key cannot run database migrations. It is intentionally
limited to client-side requests governed by Row Level Security.
