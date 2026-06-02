// 文件：合集记录提供者
//
// 路径：`lib/features/history/application/collection_records_provider.dart`。
//
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bazi_record.dart';
import '../../auth/application/auth_controller.dart';
import 'bazi_records_list_controller.dart';
import 'collections_list_controller.dart';
import 'save_bazi_record.dart' show baziRecordRepositoryProvider;

const _collectionFetchTimeout = Duration(seconds: 8);

/// 合集中包含的排盘记录（按合集 ID 匹配，保留合集中全部条目）。
final collectionRecordsProvider =
    FutureProvider.autoDispose.family<List<BaziRecord>, String>(
  (ref, collectionId) async {
    final userId = ref.read(authControllerProvider).user?.id;
    if (userId == null) return [];

    final colRepo = ref.read(collectionRepositoryProvider);
    final ids = await colRepo
        .getRecordIds(collectionId)
        .timeout(_collectionFetchTimeout);
    if (ids.isEmpty) return [];

    final idSet = ids.toSet();
    var records = await _resolveCollectionRecords(ref, userId, idSet);

    if (records.length < ids.length) {
      await ref.read(baziRecordsListProvider.notifier).refresh(silent: true);
      records = await _resolveCollectionRecords(ref, userId, idSet);
    }

    if (records.length < ids.length) {
      final repo = ref.read(baziRecordRepositoryProvider);
      final fresh = await repo
          .listByUser(userId)
          .timeout(_collectionFetchTimeout);
      records = fresh.where((r) => idSet.contains(r.id)).toList();
    }

    return _orderByCollectionIds(records, ids);
  },
);

Future<List<BaziRecord>> _resolveCollectionRecords(
  Ref ref,
  String userId,
  Set<String> idSet,
) async {
  await ref.read(baziRecordsListProvider.notifier).ensureLoaded();
  return ref
      .read(baziRecordsListProvider)
      .records
      .where((r) => idSet.contains(r.id))
      .toList();
}

List<BaziRecord> _orderByCollectionIds(
  List<BaziRecord> records,
  List<String> ids,
) {
  final byId = {for (final r in records) r.id: r};
  return [
    for (final id in ids)
      if (byId.containsKey(id)) byId[id]!,
  ];
}
