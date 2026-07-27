# Tavola release checklist

## Local quality gate

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Verify web build with the production Supabase URL and publishable key.

## Supabase

- [ ] Apply every migration in `supabase/migrations` in timestamp order.
- [ ] Verify RLS and tenant isolation with a user belonging to two restaurants.
- [ ] Verify onboarding, invitations, PIN reset/lockout, payments, and order/kitchen transitions.
- [ ] Confirm no service-role or secret key is bundled into Flutter.

## Product smoke test

- [ ] Sign up, confirm email, sign in, and complete restaurant onboarding.
- [ ] Sign out and confirm redirect to Welcome.
- [ ] Reset password and complete the recovery flow.
- [ ] Redeem an invitation and verify restaurant and role.
- [ ] Create/reset a staff PIN and verify incorrect-PIN lockout.
- [ ] Exercise dashboard/report filters, refresh, export, and stable-ID drill-down routes.
- [ ] Exercise loading, empty, error, retry, confirmation, keyboard, compact, and desktop states.
