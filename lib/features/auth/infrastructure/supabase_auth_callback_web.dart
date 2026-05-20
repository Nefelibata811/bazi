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
