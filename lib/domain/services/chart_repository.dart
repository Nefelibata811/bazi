import '../entities/saved_chart.dart';

abstract class ChartRepository {
  Future<SavedChart> save({
    required String userId,
    required String title,
    required String requestJson,
    required String reportJson,
  });

  Future<List<SavedChart>> listByUser(String userId);

  Future<void> delete(String chartId);

  Future<SavedChart?> getById(String chartId);

  Future<int> countByUser(String userId);
}
