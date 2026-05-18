import 'dart:html' as html;

const _recoveryStorageKey = 'bazi_auth_recovery';

Uri currentAuthUri() => Uri.parse(html.window.location.href);

void persistRecoveryFlag() {
  html.window.sessionStorage[_recoveryStorageKey] = '1';
}

bool hasPersistedRecoveryFlag() {
  return html.window.sessionStorage[_recoveryStorageKey] == '1';
}

void clearPersistedRecoveryFlag() {
  html.window.sessionStorage.remove(_recoveryStorageKey);
}

void cleanAuthParamsFromBrowserUrl() {
  final path = html.window.location.pathname;
  if (path != null && path.isNotEmpty) {
    html.window.history.replaceState(null, '', path);
  }
}
