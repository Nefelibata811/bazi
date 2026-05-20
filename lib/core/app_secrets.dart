import 'package:flutter/foundation.dart';

/// Runtime secrets via --dart-define. Debug builds may use fallbacks for local dev.
class AppSecrets {
  AppSecrets._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iczcdybxotqzwatyvqdm.supabase.co',
  );

  static const _supabaseAnonFromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseAnonKey {
    if (_supabaseAnonFromEnv.isNotEmpty) return _supabaseAnonFromEnv;
    assert(
      () {
        if (kDebugMode) return true;
        return false;
      }(),
      'SUPABASE_ANON_KEY must be set for release builds',
    );
    // Debug-only fallback so `flutter run` works without defines.
    if (kDebugMode) {
      return 'sb_publishable_C1tZZqL3i-HYl3D-a8-6uA_DyzgVgV6';
    }
    return '';
  }

  static const _deepseekFromEnv = String.fromEnvironment('DEEPSEEK_API_KEY');

  static String get deepseekApiKey {
    if (_deepseekFromEnv.isNotEmpty) return _deepseekFromEnv;
    assert(
      () {
        if (kDebugMode) return true;
        return false;
      }(),
      'DEEPSEEK_API_KEY must be set for release builds',
    );
    // Debug: no baked-in key — use secrets.local.env via scripts/run_web.ps1
    return '';
  }

  static const deepseekBaseUrl = String.fromEnvironment(
    'DEEPSEEK_BASE_URL',
    defaultValue: 'https://api.deepseek.com',
  );
}
