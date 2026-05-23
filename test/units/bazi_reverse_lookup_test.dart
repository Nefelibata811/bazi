import 'package:bazi_app/domain/entities/bazi_reverse_query.dart';
import 'package:bazi_app/infrastructure/calendar/lunar_bazi_reverse_lookup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lookup = LunarBaziReverseLookup();

  test('四柱齐全时反查庚寅己丑壬午丙午', () async {
    final results = await lookup.search(
      const BaziReverseQuery(
        yearGanZhi: '庚寅',
        monthGanZhi: '己丑',
        dayGanZhi: '壬午',
        timeGanZhi: '丙午',
        startYear: 2010,
        endYear: 2015,
      ),
    );
    expect(results, isNotEmpty);
    expect(
      results.any((c) => c.solarDateTime.year == 2011 && c.solarDateTime.month == 1),
      isTrue,
    );
    expect(results.first.timeGanZhi, '丙午');
  });

  test('仅年柱时返回多条候选', () async {
    final results = await lookup.search(
      const BaziReverseQuery(
        yearGanZhi: '甲子',
        startYear: 1984,
        endYear: 1984,
        maxResults: 5,
      ),
    );
    expect(results.length, greaterThan(0));
    expect(results.length, lessThanOrEqualTo(5));
    for (final c in results) {
      expect(c.yearGanZhi, '甲子');
    }
  });
}
