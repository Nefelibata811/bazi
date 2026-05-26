import 'package:flutter/foundation.dart';

/// Runtime secrets via --dart-define (see scripts/sync_dart_defines.ps1).
class AppSecrets {
  AppSecrets._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

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
    return '';
  }

  static const deepseekBaseUrl = String.fromEnvironment(
    'DEEPSEEK_BASE_URL',
    defaultValue: 'https://api.deepseek.com',
  );
}
