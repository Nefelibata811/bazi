import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/auth_controller.dart';

// ignore: avoid_web_libraries_in_flutter
import 'supabase_auth_callback_web.dart'
    if (dart.library.io) 'supabase_auth_callback_stub.dart' as platform;

/// Handles Supabase email link callbacks (password recovery, magic link).
class SupabaseAuthCallback {
  /// Parses auth params from the current URL and establishes a session when valid.
  /// Returns true when the user should land on [ResetPasswordPage].
  static Future<bool> handle() async {
    final uri = platform.currentAuthUri();
    final hadAuthParams = _hasAuthParams(uri);

    if (_isRecoveryUrl(uri)) {
      markPendingPasswordRecovery();
      platform.persistRecoveryFlag();
    } else if (platform.hasPersistedRecoveryFlag()) {
      markPendingPasswordRecovery();
    }

    if (!hadAuthParams) {
      return peekPendingPasswordRecovery();
    }

    var recoveryFromEvent = false;
    final subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        recoveryFromEvent = true;
        markPendingPasswordRecovery();
        platform.persistRecoveryFlag();
      }
    });

    try {
      final response =
          await Supabase.instance.client.auth.getSessionFromUrl(uri);

      if (_isRecoveryRedirectType(response.redirectType)) {
        markPendingPasswordRecovery();
        platform.persistRecoveryFlag();
      } else if (_isRecoveryUrl(uri) &&
          Supabase.instance.client.auth.currentSession != null) {
        markPendingPasswordRecovery();
        platform.persistRecoveryFlag();
      }
    } catch (e) {
      debugPrint('解析邮箱验证链接失败: $e');
      if (_isRecoveryUrl(uri)) {
        markPendingPasswordRecovery();
        platform.persistRecoveryFlag();
      }
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 32));
      await subscription.cancel();
    }

    final isRecovery = recoveryFromEvent ||
        peekPendingPasswordRecovery() ||
        _isRecoveryUrl(uri);

    if (isRecovery) {
      platform.persistRecoveryFlag();
    }

    return isRecovery;
  }

  /// After recovery session is established, strip tokens from the address bar.
  static void cleanUrlAfterRecoveryHandled() {
    platform.cleanAuthParamsFromBrowserUrl();
  }

  static void clearRecoveryArtifacts() {
    consumePendingPasswordRecovery();
    platform.clearPersistedRecoveryFlag();
    cleanUrlAfterRecoveryHandled();
  }

  static bool _hasAuthParams(Uri uri) {
    if (uri.fragment.isNotEmpty) return true;
    if (uri.queryParameters.containsKey('code')) return true;
    if (uri.queryParameters.containsKey('access_token')) return true;
    if (uri.queryParameters.containsKey('token_hash')) return true;
    if (uri.queryParameters['type'] == 'recovery') return true;
    return false;
  }

  static bool _isRecoveryUrl(Uri uri) {
    if (uri.queryParameters['type'] == 'recovery') return true;

    final fragment = uri.fragment;
    if (fragment.contains('type=recovery')) return true;

    if (fragment.isNotEmpty) {
      final fragQuery = fragment.startsWith('#')
          ? fragment.substring(1)
          : fragment.startsWith('?')
              ? fragment.substring(1)
              : fragment;
      final params = Uri.splitQueryString(fragQuery);
      if (params['type'] == 'recovery') return true;
    }

    return false;
  }

  static bool _isRecoveryRedirectType(String? redirectType) {
    if (redirectType == null) return false;
    return redirectType == 'recovery' ||
        redirectType == AuthChangeEvent.passwordRecovery.name;
  }
}
