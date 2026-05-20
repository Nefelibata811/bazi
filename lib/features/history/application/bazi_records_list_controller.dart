import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bazi_record.dart';
import '../../auth/application/auth_controller.dart';
import '../infrastructure/bazi_records_local_cache.dart';
import 'save_bazi_record.dart' show baziRecordRepositoryProvider;

/// Single bump counter for all record-list consumers (AI picker, 命主列表, etc.).
final baziRecordsVersionProvider = StateProvider<int>((ref) => 0);

/// @deprecated Use [baziRecordsVersionProvider].
final refreshPeopleListProvider = baziRecordsVersionProvider;

/// @deprecated Use [baziRecordsVersionProvider].
final baziRecordsRefreshProvider = baziRecordsVersionProvider;

@immutable
class BaziRecordsListState {
  const BaziRecordsListState({
    this.records = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  final List<BaziRecord> records;
  final bool isLoading;
  final bool isRefreshing;
  final Object? error;

  bool get hasRecords => records.isNotEmpty;
}

class BaziRecordsListNotifier extends Notifier<BaziRecordsListState> {
  static const _networkTimeout = Duration(seconds: 3);
  static const _maxAttempts = 2;

  String? _activeUserId;
  bool _bootstrapInFlight = false;

  @override
  BaziRecordsListState build() {
    ref.keepAlive();
    ref.listen<int>(baziRecordsVersionProvider, (previous, next) {
      if (previous == null) return;
      if (previous == next) return;
      unawaited(refresh(silent: true));
    });

    final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
    if (userId == null) {
      _activeUserId = null;
      return const BaziRecordsListState();
    }

    if (userId != _activeUserId) {
      _activeUserId = userId;
      unawaited(_bootstrap(userId));
      return const BaziRecordsListState(isLoading: true);
    }

    return state;
  }

  /// Preload after login or before opening AI tab (non-blocking).
  Future<void> ensureLoaded() async {
    final userId = ref.read(authControllerProvider).user?.id;
    if (userId == null) return;
    if (state.hasRecords && !state.isLoading) {
      unawaited(refresh(silent: true));
      return;
    }
    await _bootstrap(userId);
  }

  Future<void> refresh({bool silent = false}) async {
    final userId = ref.read(authControllerProvider).user?.id;
    if (userId == null) return;

    if (!silent) {
      state = BaziRecordsListState(
        records: state.records,
        isRefreshing: state.hasRecords,
        isLoading: !state.hasRecords,
      );
    } else if (state.hasRecords) {
      state = BaziRecordsListState(records: state.records, isRefreshing: true);
    }

    try {
      final fresh = await _fetchFromNetwork(userId);
      await BaziRecordsLocalCache.save(userId, fresh);
      state = BaziRecordsListState(records: fresh);
    } catch (e) {
      if (state.hasRecords) {
        state = BaziRecordsListState(records: state.records);
      } else {
        final cached = await BaziRecordsLocalCache.load(userId);
        if (cached.isNotEmpty) {
          state = BaziRecordsListState(records: cached);
        } else {
          state = BaziRecordsListState(error: e);
        }
      }
    }
  }

  void upsertRecord(BaziRecord record) {
    final list = [
      record,
      ...state.records.where((r) => r.id != record.id),
    ];
    state = BaziRecordsListState(records: list);
    final userId = _activeUserId;
    if (userId != null) {
      unawaited(BaziRecordsLocalCache.save(userId, list));
    }
  }

  void removeRecord(String recordId) {
    final list = state.records.where((r) => r.id != recordId).toList();
    state = BaziRecordsListState(records: list);
    final userId = _activeUserId;
    if (userId != null) {
      unawaited(BaziRecordsLocalCache.save(userId, list));
    }
  }

  Future<void> _bootstrap(String userId) async {
    if (_bootstrapInFlight && _activeUserId == userId) return;
    _bootstrapInFlight = true;

    try {
      final cached = await BaziRecordsLocalCache.load(userId);
      if (cached.isNotEmpty) {
        state = BaziRecordsListState(records: cached, isRefreshing: true);
      } else {
        state = const BaziRecordsListState(isLoading: true);
      }

      try {
        final fresh = await _fetchFromNetwork(userId);
        await BaziRecordsLocalCache.save(userId, fresh);
        if (_activeUserId == userId) {
          state = BaziRecordsListState(records: fresh);
        }
      } catch (e) {
        if (cached.isNotEmpty && _activeUserId == userId) {
          state = BaziRecordsListState(records: cached);
        } else if (_activeUserId == userId) {
          state = BaziRecordsListState(error: e);
        }
      }
    } finally {
      _bootstrapInFlight = false;
    }
  }

  Future<List<BaziRecord>> _fetchFromNetwork(String userId) async {
    final repo = ref.read(baziRecordRepositoryProvider);
    Object? lastError;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        return await repo
            .listByUser(userId)
            .timeout(_networkTimeout);
      } catch (e) {
        lastError = e;
        if (attempt + 1 >= _maxAttempts) break;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    throw lastError ?? Exception('加载命盘列表失败');
  }
}

final baziRecordsListProvider =
    NotifierProvider<BaziRecordsListNotifier, BaziRecordsListState>(
  BaziRecordsListNotifier.new,
);

/// AI 选盘等场景使用的扁平列表（与 [baziRecordsListProvider] 同源，不重复请求）。
final userRecordsProvider = Provider<List<BaziRecord>>((ref) {
  return ref.watch(baziRecordsListProvider).records;
});

List<BaziRecord> groupLatestRecordsPerPerson(List<BaziRecord> records) {
  final seen = <String>{};
  final result = <BaziRecord>[];
  for (final r in records) {
    if (seen.add(r.personName)) {
      result.add(r);
    }
  }
  return result;
}
