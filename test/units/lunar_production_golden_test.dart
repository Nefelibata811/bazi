// 文件：单元测试 — 农历productiongolden
//
// 验证 农历productiongolden 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/services/bazi_rule_engine.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:bazi_app/infrastructure/calendar/lunar_bazi_calculator.dart';
import 'package:bazi_app/infrastructure/calendar/lunar_eight_char_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final calculator = LunarBaziCalculator(ruleEngine: BaziRuleEngine());

  final cases = <({
    DateTime birth,
    String year,
    String month,
    String day,
    String hour,
  })>[
    (
      birth: DateTime(2005, 12, 23, 8, 37),
      year: '乙酉',
      month: '戊子',
      day: '辛巳',
      hour: '壬辰',
    ),
    (
      birth: DateTime(1990, 8, 15, 14, 20),
      year: '庚午',
      month: '甲申',
      day: '壬子',
      hour: '丁未',
    ),
    (
      birth: DateTime(1995, 12, 18, 10, 28),
      year: '乙亥',
      month: '戊子',
      day: '癸未',
      hour: '丁巳',
    ),
  ];

  for (final c in cases) {
    test('生产四柱 ${c.birth} 与 lunar EightChar 一致', () async {
      final request = BaziRequest(
        calendarType: CalendarType.solar,
        gender: Gender.male,
        solarDateTime: c.birth,
        lunarYear: c.birth.year,
        lunarMonth: c.birth.month,
        lunarDay: c.birth.day,
        isLeapMonth: false,
      );
      final chart = await calculator.calculate(request);
      final ec = LunarEightCharFactory.eightCharFromRequest(request);

      expect(chart.day.label, '日');
      expect(chart.year.label, '年');
      expect('${chart.year.stem}${chart.year.branch}', c.year);
      expect('${chart.month.stem}${chart.month.branch}', c.month);
      expect('${chart.day.stem}${chart.day.branch}', c.day);
      expect('${chart.hour.stem}${chart.hour.branch}', c.hour);

      expect('${chart.year.stem}${chart.year.branch}',
          '${ec.getYearGan()}${ec.getYearZhi()}');
      expect('${chart.month.stem}${chart.month.branch}',
          '${ec.getMonthGan()}${ec.getMonthZhi()}');
      expect('${chart.day.stem}${chart.day.branch}',
          '${ec.getDayGan()}${ec.getDayZhi()}');
      expect('${chart.hour.stem}${chart.hour.branch}',
          '${ec.getTimeGan()}${ec.getTimeZhi()}');
    });
  }
}
