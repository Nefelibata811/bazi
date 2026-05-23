import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/services/bazi_rule_engine.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:bazi_app/infrastructure/calendar/lunar_bazi_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final calculator = LunarBaziCalculator(ruleEngine: BaziRuleEngine());

  test('四柱附带命宫身宫胎元胎息', () async {
    final chart = await calculator.calculate(
      BaziRequest(
        calendarType: CalendarType.solar,
        gender: Gender.female,
        solarDateTime: DateTime(1990, 8, 15, 14, 20),
        lunarYear: 1990,
        lunarMonth: 7,
        lunarDay: 25,
        isLeapMonth: false,
      ),
    );

    expect(chart.extraPillars.length, 4);
    expect(
      chart.extraPillars.map((p) => p.label).toList(),
      ['命宫', '身宫', '胎元', '胎息'],
    );
    for (final p in chart.extraPillars) {
      expect(p.stem.length, 1);
      expect(p.branch.length, 1);
      expect(p.tenGod, isNotEmpty);
    }
    expect(chart.allPillars.length, 8);
  });
}
