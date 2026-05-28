// 文件：Supabase认证callbackweb
//
// 路径：`lib/features/auth/infrastructure/supabase_auth_callback_web.dart`。
//
import 'package:web/web.dart';

const _recoveryStorageKey = 'bazi_auth_recovery';

Uri currentAuthUri() => Uri.parse(window.location.href);

void persistRecoveryFlag() {
  window.sessionStorage.setItem(_recoveryStorageKey, '1');
}

bool hasPersistedRecoveryFlag() {
  return window.sessionStorage.getItem(_recoveryStorageKey) == '1';
}

void clearPersistedRecoveryFlag() {
  window.sessionStorage.removeItem(_recoveryStorageKey);
}

void cleanAuthParamsFromBrowserUrl() {
  final path = window.location.pathname;
  if (path.isNotEmpty) {
    window.history.replaceState(null, '', path);
  }
}
