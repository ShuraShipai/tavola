# Tavola

Restaurant POS web application built with Flutter, Riverpod, and Supabase.

## Supabase connection

Tavola is configured for the linked Supabase project. You may override its URL
and publishable key at run time for another project. Do not use a service-role
or secret key in Flutter.

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

The checked-in credentials are a Supabase publishable client key, not a
service-role key. Database access still requires properly configured RLS
policies.

## Quality gate

Run the same checks used by CI before opening a pull request:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

See [docs/release-checklist.md](docs/release-checklist.md) for Supabase,
tenant-isolation, workflow, and release smoke checks.

<!-- Legacy Flutter links retained below for reference. -->

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
