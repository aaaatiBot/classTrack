import 'package:shared_preferences/shared_preferences.dart';

class SupabaseConfig {
  // Built-in defaults or environment variables passed via --dart-define
  static const String _envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tppijfsqlfzzdpzcggch.supabase.co',
  );
  static const String _envAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRwcGlqZnNxbGZ6emRwemNnZ2NoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM2OTM4MzEsImV4cCI6MjEwOTI2OTgzMX0.zc548ZmY6vatnKPBav1VPIKcVJ_st4_8OgwZtFluI6Y',
  );

  static const String _keyUrl = 'supabase_url';
  static const String _keyAnonKey = 'supabase_anon_key';

  static String currentUrl = _envUrl;
  static String currentAnonKey = _envAnonKey;

  static bool get isConfigured =>
      currentUrl.trim().isNotEmpty &&
      currentAnonKey.trim().isNotEmpty &&
      !currentUrl.contains('YOUR_SUPABASE_PROJECT_URL');

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_keyUrl);
    final savedKey = prefs.getString(_keyAnonKey);

    if (savedUrl != null && savedUrl.isNotEmpty) {
      currentUrl = savedUrl;
    }
    if (savedKey != null && savedKey.isNotEmpty) {
      currentAnonKey = savedKey;
    }
  }

  static Future<void> saveConfig(String url, String anonKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, url.trim());
    await prefs.setString(_keyAnonKey, anonKey.trim());
    currentUrl = url.trim();
    currentAnonKey = anonKey.trim();
  }
}
