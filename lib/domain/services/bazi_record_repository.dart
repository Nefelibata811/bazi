// 文件：八字记录仓库
//
// 路径：`lib/domain/services/bazi_record_repository.dart`。
//
import '../entities/bazi_record.dart';

abstract class BaziRecordRepository {
  Future<BaziRecord> save({
    required String userId,
    required String personName,
    required String requestJson,
    required String reportJson,
  });

  /// 已保存则返回该记录，否则 null（不修改已有数据）。
  Future<BaziRecord?> findByIdentity({
    required String userId,
    required String personName,
    required String requestJson,
  });

  Future<List<BaziRecord>> listByUser(String userId);

  Future<List<String>> listPersonNames(String userId);

  Future<List<BaziRecord>> listByPerson(String userId, String personName);

  Future<void> delete(String recordId);

  Future<void> deleteByPerson(String userId, String personName);

  Future<void> deleteByPersonIdentity({
    required String userId,
    required String displayName,
    required String birthFingerprint,
  });
}

abstract class CollectionRepository {
  Future<List<CollectionModel>> listByUser(String userId);

  Future<CollectionModel> create({
    required String userId,
    required String name,
  });

  Future<void> rename(String collectionId, String newName);

  Future<void> addRecord(String collectionId, String recordId);

  Future<void> removeRecord(String collectionId, String recordId);

  Future<List<String>> getRecordIds(String collectionId);

  Future<void> deleteCollection(String collectionId);
}

/// 类 `CollectionModel`：实现 Collection Model 相关逻辑。
class CollectionModel {
  const CollectionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
}
