import '../../domain/entities/saved_chart.dart';
import '../../domain/services/chart_repository.dart';
import 'database_service.dart';

class SqliteChartRepository implements ChartRepository {
  @override
  Future<SavedChart> save({
    required String userId,
    required String title,
    required String requestJson,
    required String reportJson,
  }) async {
    final db = await DatabaseService.instance;
    final now = DateTime.now().toIso8601String();
    final chartId = DatabaseService.hashId('$userId$title${DateTime.now().millisecondsSinceEpoch}');

    await db.insert('saved_charts', {
      'id': chartId,
      'user_id': userId,
      'title': title,
      'request_json': requestJson,
      'report_json': reportJson,
      'saved_at': now,
    });

    return SavedChart(
      id: chartId,
      userId: userId,
      title: title,
      requestJson: requestJson,
      reportJson: reportJson,
      savedAt: DateTime.parse(now),
    );
  }

  @override
  Future<List<SavedChart>> listByUser(String userId) async {
    final db = await DatabaseService.instance;
    final rows = await db.query(
      'saved_charts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'saved_at DESC',
    );

    return rows.map((row) {
      return SavedChart(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        title: row['title'] as String,
        requestJson: row['request_json'] as String,
        reportJson: row['report_json'] as String,
        savedAt: DateTime.parse(row['saved_at'] as String),
      );
    }).toList();
  }

  @override
  Future<void> delete(String chartId) async {
    final db = await DatabaseService.instance;
    await db.delete(
      'saved_charts',
      where: 'id = ?',
      whereArgs: [chartId],
    );
  }

  @override
  Future<SavedChart?> getById(String chartId) async {
    final db = await DatabaseService.instance;
    final rows = await db.query(
      'saved_charts',
      where: 'id = ?',
      whereArgs: [chartId],
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    return SavedChart(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      requestJson: row['request_json'] as String,
      reportJson: row['report_json'] as String,
      savedAt: DateTime.parse(row['saved_at'] as String),
    );
  }

  @override
  Future<int> countByUser(String userId) async {
    final db = await DatabaseService.instance;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM saved_charts WHERE user_id = ?',
      [userId],
    );
    return result.first['cnt'] as int;
  }
}
