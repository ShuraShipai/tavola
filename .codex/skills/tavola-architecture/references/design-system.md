(# Tavola Design System

Use `../tavola-design/Restaurant billing system .html` from the Tavola repository root as the source design handoff. It is a static prototype for a staff-facing restaurant POS and should guide visual fidelity, not application structure.

## Core tokens

- Font: Inter with system sans-serif fallback.
- Brand: slate `#1E293B`; accent amber `#F59E0B`; accent dark `#D97706`.
- Surface/background: `#FFFFFF` / `#F8FAFC`; borders: `#E2E8F0` and `#CBD5E1`.
- Semantic colors: success `#22C55E`, error `#EF4444`, info `#3B82F6`, warning amber.
- Spacing: 4, 8, 12, 16, 24, 32, 40, 48, 64.
- Radius: 8, 12, 16, 24; use restrained shadows and visible keyboard focus.
- Shell: 264px sidebar and 72px top bar on expanded layouts.

## Product areas

The prototype covers onboarding/authentication, dashboard, orders, tables, kitchen display, billing/payments, menu, customers, staff/permissions, reports, inventory, discounts, settings, branches/daily operations, reservations, support, and system status.

## Fidelity rules

- Reuse theme tokens and shared widgets; do not use ad-hoc colors, spacing, or typography in feature pages.
- Preserve all loading, empty, error, disabled, confirmation, dialog, and print states shown or implied by the prototype.
- Keep desktop layouts efficient for POS staff and collapse gracefully at tablet and compact browser widths.
- Use accessible labels, keyboard navigation, focus rings, semantic states, and touch targets of at least 44px.
