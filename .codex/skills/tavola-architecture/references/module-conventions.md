# Tavola Module Conventions

## Flutter

```text
lib/features/<feature>/
  data/{datasources,models,repositories}
  domain/{entities,repositories,usecases}
  presentation/{pages,providers,widgets}
```

- Entities and repository interfaces belong to `domain` and must not import Flutter, Riverpod, HTTP, or Supabase types.
- Data models map Supabase rows and RPC responses to domain entities inside data repositories.
- A provider exposes a use case or feature controller; pages render provider state and dispatch user intent.
- Keep shared UI in `core/widgets`; keep common configuration, formatting, network, errors, and utilities in `core`.

## Supabase

```text
supabase/
  migrations
  functions/<function-name>
```

- Migrations own tables, constraints, indexes, database functions, and RLS policies.
- Edge Functions own privileged server-side orchestration and external integrations.
- Flutter data repositories own Supabase client calls and map rows to domain entities.

## Cross-cutting rules

- Authenticate every protected operation with Supabase Auth; derive actor from the JWT and restaurant membership, never from a client-supplied ownership field.
- Authorize actions with RLS policies and Edge Functions, not page visibility.
- Make status transitions explicit and validate their permitted predecessors.
- Persist immutable snapshots and audit entries for billable actions; do not mutate historical financial facts.
- Use Supabase queries/RPC for request-response work and Supabase Realtime for live synchronization. Publish realtime changes only after durable persistence succeeds.
