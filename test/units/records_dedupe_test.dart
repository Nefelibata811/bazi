// 文件：单元测试 — 记录dedupe
//
// 验证 记录dedupe 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/domain/entities/bazi_record.dart';
import 'package:bazi_app/features/history/infrastructure/person_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BaziRecord record({
    required String id,
    required String name,
    required String solar,
    required DateTime savedAt,
  }) {
    return BaziRecord(
      id: id,
      userId: 'u1',
      personName: name,
      requestJson:
          '{"calendarType":"solar","gender":"male","solarDateTime":"$solar",'
          '"lunarYear":1990,"lunarMonth":1,"lunarDay":1,"isLeapMonth":false,'
          '"baziSect":"sameDay","personName":"$name"}',
      reportJson: '{}',
      savedAt: savedAt,
    );
  }

  test('同名同出生只保留最近一条', () {
    final list = PersonIdentity.dedupeRecords([
      record(
        id: '1',
        name: 'sjy',
        solar: '1990-08-15T14:20:00.000',
        savedAt: DateTime(2026, 1, 1),
      ),
      record(
        id: '2',
        name: 'sjy',
        solar: '1990-08-15T14:20:00.000',
        savedAt: DateTime(2026, 5, 1),
      ),
    ]);
    expect(list.length, 1);
    expect(list.first.id, '2');
  });

  test('同名不同出生保留两条', () {
    final list = PersonIdentity.dedupeRecords([
      record(
        id: '1',
        name: 'sjy',
        solar: '1990-08-15T14:20:00.000',
        savedAt: DateTime(2026, 1, 1),
      ),
      record(
        id: '2',
        name: 'sjy',
        solar: '1991-08-15T14:20:00.000',
        savedAt: DateTime(2026, 1, 2),
      ),
    ]);
    expect(list.length, 2);
  });
}
