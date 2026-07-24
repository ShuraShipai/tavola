abstract final class SupabaseConfig {
  // Publishable client credentials are intentionally safe to ship in Flutter.
  // `--dart-define` values can override these for another Supabase project.
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kxudwhbrcsqccclwmhla.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_NCFu8VsIfNtg4esJgFpCUw_V-ksxS0P',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
