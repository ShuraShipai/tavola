---
name: tavola-architecture
description: Build, review, plan, or refactor the Tavola restaurant POS web application. Use for Flutter Web, Clean Architecture, Riverpod, Supabase, Tavola design fidelity, GoRouter, billing, kitchen, table, menu, reservation, staff, and operational workflow changes in this repository.
---

# Tavola Architecture

Implement Tavola as a staff-facing, desktop-first restaurant POS. Preserve the sibling static handoff at `../tavola-design/Restaurant billing system .html` as the visual source of truth; do not port its static HTML directly.

## Workflow

1. Inspect the relevant handoff screen and its reusable token/component CSS before changing UI.
2. Identify the owning feature and keep dependencies directed inward: presentation → domain ← data.
3. Add the smallest complete vertical slice: entity and repository port, use case, repository adapter, Riverpod provider, page/widget, tests.
4. Protect restaurant tenancy, role permissions, monetary correctness, and audit history in every operational change.
5. Format and verify the affected Flutter and API tests before handoff.

## Flutter Web

- Use `lib/app` for application composition and routing; use `lib/core` only for cross-feature concerns.
- Place feature code in `lib/features/<feature>/{data,domain,presentation}`. Keep pages, providers, and feature widgets under `presentation`.
- Represent async data with Riverpod providers and `AsyncValue`; keep widgets free of repository and HTTP details.
- Use `TavolaTheme`, `TavolaColors`, `TavolaSpace`, `TavolaRadius`, `TavolaSize`, and shared widgets before adding local styling.
- Build desktop-first layouts with `TavolaBreakpoints`; preserve usable compact/tablet browser states.
- Add GoRouter routes through `AppRoutes` and apply authorization redirects before building protected pages.

## Supabase

- Use Supabase Auth, Postgres, Row Level Security, Realtime, Storage, and Edge Functions; do not create a separate server backend.
- Scope every table, query, and realtime subscription by `restaurant_id`; enforce tenant and role access through RLS policies, never through the Flutter UI alone.
- Keep Supabase adapters in feature data repositories. Domain entities, repository ports, and use cases must not depend on Supabase types.
- Enforce Owner, Manager, Cashier, Waiter, and Kitchen permissions in RLS policies and privileged Edge Functions. Treat client-side guards as navigation convenience only.
- Store billing as auditable records: order snapshots, totals, taxes, discounts, split payments, refunds/voids, invoices, shifts, and settlements. Use integer minor currency units for calculations.
- Subscribe to Supabase Realtime for order, table, kitchen, payment, and notification changes. Use Edge Functions for privileged actions and future payment integrations.

## References

- Read `references/design-system.md` for the handoff tokens, screens, and UI fidelity rules.
- Read `references/module-conventions.md` before adding a feature, API endpoint, Riverpod provider, or test.

## Verification

- Run `dart format lib test`, `flutter analyze`, and `flutter test` for Flutter changes.
- Test Supabase migrations, RLS policies, Edge Functions, and Flutter repositories; verify tenancy, permissions, monetary calculations, and state transitions.
