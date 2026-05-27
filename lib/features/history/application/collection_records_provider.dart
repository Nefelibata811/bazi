import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bazi_record.dart';
import 'bazi_records_list_controller.dart';
import 'collections_list_controller.dart';

const _collectionFetchTimeout = Duration(seconds: 8);

/// 合集中包含的排盘记录（按合集 ID 匹配，保留合集中全部条目）。
final collectionRecordsProvider =
    FutureProvider.autoDispose.family<List<BaziRecord>, String>(
  (ref, collectionId) async {
    final repo = ref.read(collectionRepositoryProvider);
    final ids = await repo
        .getRecordIds(collectionId)
        .timeout(_collectionFetchTimeout);
    if (ids.isEmpty) return [];

    final listState = ref.read(baziRecordsListProvider);
    if (!listState.hasRecords) {
      await ref.read(baziRecordsListProvider.notifier).ensureLoaded();
    }

    final idSet = ids.toSet();
    return ref
        .read(baziRecordsListProvider)
        .records
        .where((r) => idSet.contains(r.id))
        .toList();
  },
);
