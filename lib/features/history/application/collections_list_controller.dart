// 文件：collectionslist控制器
//
// 控制器：管理状态并协调数据层。
// 路径：`lib/features/history/application/collections_list_controller.dart`。
//
// 命盘合集列表：keepAlive 缓存，主页预加载，避免每次进入重复请求。

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/services/bazi_record_repository.dart';
import '../../../infrastructure/database/supabase_collection_repository.dart';
import '../../auth/application/auth_controller.dart';

final collectionRepositoryProvider = Provider<SupabaseCollectionRepository>((ref) {
  return SupabaseCollectionRepository(Supabase.instance.client);
});

@immutable
/// 类 `CollectionsListState`：实现 Collections List State 相关逻辑。
class CollectionsListState {
  const CollectionsListState({
    this.collections = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  final List<CollectionModel> collections;
  final bool isLoading;
  final bool isRefreshing;
  final Object? error;

  bool get hasCollections => collections.isNotEmpty;
}

/// 类 `CollectionsListNotifier`：实现 Collections List Notifier 相关逻辑。
class CollectionsListNotifier extends Notifier<CollectionsListState> {
  static const _networkTimeout = Duration(seconds: 3);

  String? _activeUserId;
  Future<void>? _ongoingBootstrap;

  @override
  // 构建界面布局。
  CollectionsListState build() {
    ref.keepAlive();

    final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
    if (userId == null) {
      _activeUserId = null;
      return const CollectionsListState();
    }

    if (userId != _activeUserId) {
      _activeUserId = userId;
      unawaited(_bootstrap(userId));
      return const CollectionsListState(isLoading: true);
    }

    return state;
  }

  // 确保列表已加载；有缓存时可静默刷新。
  Future<void> ensureLoaded() async {
    final userId = ref.read(authControllerProvider).user?.id;
    if (userId == null) return;
    if (state.hasCollections && !state.isLoading) {
      unawaited(refresh(silent: true));
      return;
    }
    // 首次加载：优先读本地缓存，再请求网络。
    await _bootstrap(userId);
  }

  // 重新从网络拉取并更新状态。
  Future<void> refresh({bool silent = false}) async {
    final userId = ref.read(authControllerProvider).user?.id;
    if (userId == null) return;

    if (!silent) {
      state = CollectionsListState(
        collections: state.collections,
        isRefreshing: state.hasCollections,
        isLoading: !state.hasCollections,
      );
    } else if (state.hasCollections) {
      state = CollectionsListState(
        collections: state.collections,
        isRefreshing: true,
      );
    }

    try {
      final fresh = await _fetch(userId);
      state = CollectionsListState(collections: fresh);
    } catch (e) {
      if (state.hasCollections) {
        state = CollectionsListState(collections: state.collections);
      } else {
        state = CollectionsListState(error: e);
      }
    }
  }

  Future<CollectionModel> createCollection({
    required String userId,
    required String name,
  }) async {
    final repo = ref.read(collectionRepositoryProvider);
    final created = await repo.create(userId: userId, name: name);
    state = CollectionsListState(
      collections: [created, ...state.collections],
    );
    return created;
  }

  Future<void> renameCollection(String collectionId, String newName) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.rename(collectionId, newName);
    state = CollectionsListState(
      collections: [
        for (final c in state.collections)
          if (c.id == collectionId)
            CollectionModel(
              id: c.id,
              userId: c.userId,
              name: newName,
              createdAt: c.createdAt,
            )
          else
            c,
      ],
    );
  }

  Future<void> deleteCollection(String collectionId) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.deleteCollection(collectionId);
    state = CollectionsListState(
      collections: state.collections.where((c) => c.id != collectionId).toList(),
    );
  }

  // 首次加载：优先读本地缓存，再请求网络。
  Future<void> _bootstrap(String userId) async {
    if (_ongoingBootstrap != null && _activeUserId == userId) {
      return _ongoingBootstrap!;
    }

    final future = _runBootstrap(userId);
    _ongoingBootstrap = future;
    try {
      await future;
    } finally {
      if (identical(_ongoingBootstrap, future)) {
        _ongoingBootstrap = null;
      }
    }
  }

  Future<void> _runBootstrap(String userId) async {
    try {
      if (!state.hasCollections) {
        state = const CollectionsListState(isLoading: true);
      } else {
        state = CollectionsListState(
          collections: state.collections,
          isRefreshing: true,
        );
      }

      try {
        final fresh = await _fetch(userId);
        if (_activeUserId == userId) {
          state = CollectionsListState(collections: fresh);
        }
      } catch (e) {
        if (_activeUserId == userId && !state.hasCollections) {
          state = CollectionsListState(error: e);
        } else if (_activeUserId == userId) {
          state = CollectionsListState(collections: state.collections);
        }
      }
    } catch (e) {
      if (_activeUserId == userId && !state.hasCollections) {
        state = CollectionsListState(error: e);
      }
    }
  }

  Future<List<CollectionModel>> _fetch(String userId) async {
    final repo = ref.read(collectionRepositoryProvider);
    return repo.listByUser(userId).timeout(_networkTimeout);
  }
}

final collectionsListProvider =
    NotifierProvider<CollectionsListNotifier, CollectionsListState>(
  CollectionsListNotifier.new,
);
