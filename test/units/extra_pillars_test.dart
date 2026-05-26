import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/services/bazi_rule_engine.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:bazi_app/infrastructure/calendar/lunar_bazi_calculator.dart';
import 'package:bazi_app/infrastructure/calendar/lunar_eight_char_factory.dart';
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

  test('辅宫干支与 lunar EightChar 一致（含官方用例锚点）', () async {
    final cases = <({
      DateTime birth,
      String? ming,
      String? shen,
      String? taiYuan,
    })>[
      (
        birth: DateTime(2005, 12, 23, 8, 37),
        ming: '己丑',
        shen: null,
        taiYuan: '己卯',
      ),
      (
        birth: DateTime(1998, 6, 11, 4, 28),
        ming: '辛酉',
        shen: null,
        taiYuan: null,
      ),
      (
        birth: DateTime(1995, 12, 18, 10, 28),
        ming: '戊子',
        shen: '壬午',
        taiYuan: '己卯',
      ),
    ];

    for (final c in cases) {
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

      String gz(int i) =>
          '${chart.extraPillars[i].stem}${chart.extraPillars[i].branch}';

      expect(gz(0), ec.getMingGong(), reason: '命宫 ${c.birth}');
      expect(gz(1), ec.getShenGong(), reason: '身宫 ${c.birth}');
      expect(gz(2), ec.getTaiYuan(), reason: '胎元 ${c.birth}');
      expect(gz(3), ec.getTaiXi(), reason: '胎息 ${c.birth}');

      if (c.ming != null) expect(ec.getMingGong(), c.ming);
      if (c.shen != null) expect(ec.getShenGong(), c.shen);
      if (c.taiYuan != null) expect(ec.getTaiYuan(), c.taiYuan);
    }
  });

  test('1995-12-18 身宫与 lunar 一致', () async {
    final request = BaziRequest(
      calendarType: CalendarType.solar,
      gender: Gender.male,
      solarDateTime: DateTime(1995, 12, 18, 10, 28),
      lunarYear: 1995,
      lunarMonth: 12,
      lunarDay: 18,
      isLeapMonth: false,
    );
    final chart = await calculator.calculate(request);
    final ec = LunarEightCharFactory.eightCharFromRequest(request);
    final shen = chart.extraPillars[1];
    expect('${shen.stem}${shen.branch}', ec.getShenGong());
    expect(ec.getShenGong(), '壬午');
  });

  test('胎息为日干五合天干配日支六合地支', () async {
    final request = BaziRequest(
      calendarType: CalendarType.solar,
      gender: Gender.male,
      solarDateTime: DateTime(2005, 12, 23, 8, 37),
      lunarYear: 2005,
      lunarMonth: 12,
      lunarDay: 23,
      isLeapMonth: false,
    );
    final chart = await calculator.calculate(request);
    final ec = LunarEightCharFactory.eightCharFromRequest(request);
    final taiXi = chart.extraPillars[3];
    expect('${taiXi.stem}${taiXi.branch}', ec.getTaiXi());
    expect(taiXi.naYin, ec.getTaiXiNaYin());
  });
}
