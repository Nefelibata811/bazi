import 'package:flutter/foundation.dart';

/// Web / auth redirect URL helpers.
abstract final class AppUrls {
  /// Where Supabase password-reset emails should redirect.
  static String get passwordResetRedirect {
    if (kIsWeb) {
      return '${Uri.base.origin}/';
    }
    return 'io.supabase.baziapp://reset-password/';
  }
}
