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

class CollectionsListNotifier extends Notifier<CollectionsListState> {
  static const _networkTimeout = Duration(seconds: 3);

  String? _activeUserId;
  bool _bootstrapInFlight = false;

  @override
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

  Future<void> ensureLoaded() async {
    final userId = ref.read(authControllerProvider).user?.id;
    if (userId == null) return;
    if (state.hasCollections && !state.isLoading) {
      unawaited(refresh(silent: true));
      return;
    }
    await _bootstrap(userId);
  }

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

  Future<void> _bootstrap(String userId) async {
    if (_bootstrapInFlight && _activeUserId == userId) return;
    _bootstrapInFlight = true;

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
    } finally {
      _bootstrapInFlight = false;
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
