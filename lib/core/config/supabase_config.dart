class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_URL',
    defaultValue: 'https://gjbqjhlwowsfxfelrmbo.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_vrLet83r4IW6hIGiqQAcMw_3tJb1hVY',
  );

  static bool get configured => url.isNotEmpty && publishableKey.isNotEmpty;
}
