// 文件：登录后会话数据预加载
//
// 单一入口：后台异步拉取，不阻塞登录进主页。
//
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../auth/application/auth_controller.dart';
import '../../../app/bootstrap_app.dart';
import 'bazi_records_list_controller.dart';
import 'collections_list_controller.dart';

const _preloadDelay = Duration(milliseconds: 600);
const _preloadDebounce = Duration(seconds: 3);

String? _lastPreloadUserId;
DateTime? _lastPreloadAt;
Future<void>? _preloadInFlight;

/// 登录恢复后在后台预加载命主列表与合集（可重复调用，内部去重）。
void preloadUserDataLists(WidgetRef ref) {
  if (!ref.read(supabaseReadyProvider)) return;
  if (!isSupabaseSessionActive()) return;

  final auth = ref.read(authControllerProvider);
  if (!auth.isLoggedIn || auth.user?.id == null) return;

  final userId = auth.user!.id;
  final now = DateTime.now();
  if (_lastPreloadUserId == userId &&
      _lastPreloadAt != null &&
      now.difference(_lastPreloadAt!) < _preloadDebounce) {
    return;
  }

  if (_preloadInFlight != null && _lastPreloadUserId == userId) {
    return;
  }

  _lastPreloadUserId = userId;
  _lastPreloadAt = now;
  unawaited(_preloadInBackground(ref, userId));
}

Future<void> _preloadInBackground(WidgetRef ref, String userId) async {
  final future = _runPreload(ref, userId);
  _preloadInFlight = future;
  try {
    await future;
  } finally {
    if (identical(_preloadInFlight, future)) {
      _preloadInFlight = null;
    }
  }
}

Future<void> _runPreload(WidgetRef ref, String userId) async {
  await Future<void>.delayed(_preloadDelay);
  if (!ref.read(supabaseReadyProvider)) return;
  if (!isSupabaseSessionActive()) return;

  final auth = ref.read(authControllerProvider);
  if (!auth.isLoggedIn || auth.user?.id != userId) return;

  await Future.wait([
    ref.read(baziRecordsListProvider.notifier).ensureLoaded(),
    ref.read(collectionsListProvider.notifier).ensureLoaded(),
  ]);
}

/// 切换账号时重置去重状态。
void resetPreloadCoordinator() {
  _lastPreloadUserId = null;
  _lastPreloadAt = null;
  _preloadInFlight = null;
}
