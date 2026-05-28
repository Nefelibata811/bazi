// 文件：单元测试 — 农历大运运程calculator
//
// 验证 农历大运运程calculator 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/domain/entities/bazi_chart.dart';
import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/entities/calendar_snapshot.dart';
import 'package:bazi_app/domain/entities/lunar_date.dart';
import 'package:bazi_app/domain/entities/pillar.dart';
import 'package:bazi_app/domain/services/bazi_rule_engine.dart';
import 'package:bazi_app/domain/value_objects/calendar_precision.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:bazi_app/infrastructure/calendar/lunar_luck_cycle_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = BaziRuleEngine();
  final calculator = LunarLuckCycleCalculator(ruleEngine: engine);

  final request = BaziRequest(
    calendarType: CalendarType.solar,
    gender: Gender.male,
    solarDateTime: DateTime(2020, 6, 15, 10, 30),
    lunarYear: 2020,
    lunarMonth: 5,
    lunarDay: 1,
    isLeapMonth: false,
  );

  final chart = BaziChart(
    dayMaster: '甲',
    year: const Pillar(
      label: '年',
      stem: '庚',
      branch: '子',
      tenGod: '',
      hiddenStems: [],
      naYin: '',
      growthPhase: '',
    ),
    month: const Pillar(
      label: '月',
      stem: '壬',
      branch: '午',
      tenGod: '',
      hiddenStems: [],
      naYin: '',
      growthPhase: '',
    ),
    day: const Pillar(
      label: '日',
      stem: '甲',
      branch: '寅',
      tenGod: '',
      hiddenStems: [],
      naYin: '',
      growthPhase: '',
    ),
    hour: const Pillar(
      label: '时',
      stem: '己',
      branch: '巳',
      tenGod: '',
      hiddenStems: [],
      naYin: '',
      growthPhase: '',
    ),
  );

  final snapshot = CalendarSnapshot(
    request: request,
    solarDateTime: request.solarDateTime,
    lunarDate: const LunarDate(
      year: 2020,
      month: 5,
      day: 1,
      isLeapMonth: false,
    ),
    precision: CalendarPrecision.exact,
  );

  test('首步为起运前（index=0）且含小运干支', () async {
    final cycles = await calculator.calculate(
      request: request,
      calendarSnapshot: snapshot,
      chart: chart,
      solarTerms: const [],
    );
    expect(cycles.isNotEmpty, isTrue);
    expect(cycles.first.index, 0);
    expect(cycles.first.isPreStart, isTrue);
    expect(cycles.first.ganZhi, '起运前');
    expect(cycles.first.flowingYears.isNotEmpty, isTrue);
    expect(
      cycles.first.flowingYears.any(
        (fy) =>
            fy.xiaoYunGanZhi != null && fy.xiaoYunGanZhi!.isNotEmpty,
      ),
      isTrue,
    );
    expect(cycles.any((c) => c.index == 1), isTrue);
  });

  test('流年含十二流月', () async {
    final cycles = await calculator.calculate(
      request: request,
      calendarSnapshot: snapshot,
      chart: chart,
      solarTerms: const [],
    );
    final daYun = cycles.firstWhere((c) => c.index == 1);
    expect(daYun.flowingYears.isNotEmpty, isTrue);
    final fy = daYun.flowingYears.first;
    expect(fy.flowingMonths.length, 12);
    expect(fy.flowingMonths.first.index, 1);
    expect(fy.flowingMonths.first.monthName, isNotEmpty);
    expect(fy.flowingMonths.first.ganZhi.length, 2);
  });
}
