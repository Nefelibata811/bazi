import '../entities/bazi_record.dart';

abstract class BaziRecordRepository {
  Future<BaziRecord> save({
    required String userId,
    required String personName,
    required String requestJson,
    required String reportJson,
  });

  Future<List<BaziRecord>> listByUser(String userId);

  Future<List<String>> listPersonNames(String userId);

  Future<List<BaziRecord>> listByPerson(String userId, String personName);

  Future<void> delete(String recordId);

  Future<void> deleteByPerson(String userId, String personName);
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
