// 文件：Supabase合集仓库
//
// 路径：`lib/infrastructure/database/supabase_collection_repository.dart`。
//
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/services/bazi_record_repository.dart';

/// 类 `SupabaseCollectionRepository`：实现 Supabase Collection Repository 相关逻辑。
class SupabaseCollectionRepository implements CollectionRepository {
  final SupabaseClient _client;

  SupabaseCollectionRepository(this._client);

  @override
  Future<List<CollectionModel>> listByUser(String userId) async {
    final rows = await _client
        .from('collections')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return rows.map((row) => CollectionModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    )).toList();
  }

  @override
  Future<CollectionModel> create({
    required String userId,
    required String name,
  }) async {
    final now = DateTime.now().toIso8601String();
    final row = await _client.from('collections').insert({
      'user_id': userId,
      'name': name,
      'created_at': now,
    }).select().single();

    return CollectionModel(
      id: row['id'] as String,
      userId: userId,
      name: name,
      createdAt: DateTime.parse(now),
    );
  }

  @override
  Future<void> rename(String collectionId, String newName) async {
    await _client.from('collections').update({
      'name': newName,
    }).eq('id', collectionId);
  }

  @override
  Future<void> addRecord(String collectionId, String recordId) async {
    await _client.from('collection_records').upsert({
      'collection_id': collectionId,
      'record_id': recordId,
    });
  }

  @override
  Future<void> removeRecord(String collectionId, String recordId) async {
    await _client
        .from('collection_records')
        .delete()
        .eq('collection_id', collectionId)
        .eq('record_id', recordId);
  }

  @override
  Future<List<String>> getRecordIds(String collectionId) async {
    final rows = await _client
        .from('collection_records')
        .select('record_id')
        .eq('collection_id', collectionId);

    return rows.map((r) => r['record_id'] as String).toList();
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    await _client
        .from('collection_records')
        .delete()
        .eq('collection_id', collectionId);
    await _client.from('collections').delete().eq('id', collectionId);
  }
}
