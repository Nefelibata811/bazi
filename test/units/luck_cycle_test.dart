import 'package:bazi_app/domain/entities/bazi_chart.dart';
import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/entities/calendar_snapshot.dart';
import 'package:bazi_app/domain/entities/lunar_date.dart';
import 'package:bazi_app/domain/entities/pillar.dart';
import 'package:bazi_app/domain/entities/solar_term_info.dart';
import 'package:bazi_app/domain/services/bazi_rule_engine.dart';
import 'package:bazi_app/domain/value_objects/calendar_precision.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bazi_app/infrastructure/calendar/real_luck_cycle_calculator.dart';

void main() {
  final engine = BaziRuleEngine();
  final calculator = RealLuckCycleCalculator(ruleEngine: engine);

  final request = BaziRequest(
    calendarType: CalendarType.solar,
    gender: Gender.male,
    solarDateTime: DateTime(2024, 3, 5, 10, 23),
    lunarYear: 2024,
    lunarMonth: 2,
    lunarDay: 10,
    isLeapMonth: false,
  );

  BaziChart testChart() => BaziChart(
        dayMaster: '癸',
        year: const Pillar(
          label: '年柱',
          stem: '甲',
          branch: '辰',
          tenGod: '伤官',
          hiddenStems: [],
          naYin: '',
          growthPhase: '',
        ),
        month: const Pillar(
          label: '月柱',
          stem: '丙',
          branch: '寅',
          tenGod: '偏财',
          hiddenStems: [],
          naYin: '',
          growthPhase: '',
        ),
        day: const Pillar(
          label: '日柱',
          stem: '癸',
          branch: '未',
          tenGod: '日主',
          hiddenStems: [],
          naYin: '',
          growthPhase: '',
        ),
        hour: const Pillar(
          label: '时柱',
          stem: '辛',
          branch: '酉',
          tenGod: '偏印',
          hiddenStems: [],
          naYin: '',
          growthPhase: '',
        ),
      );

  group('RealLuckCycleCalculator', () {
    test('返回十步大运', () async {
      final cycles = await calculator.calculate(
        request: request,
        calendarSnapshot: CalendarSnapshot(
          request: request,
          solarDateTime: DateTime(2024, 3, 5, 10, 23),
          lunarDate: const LunarDate(year: 2024, month: 2, day: 10, isLeapMonth: false),
          precision: CalendarPrecision.approximate,
        ),
        chart: testChart(),
        solarTerms: [
          SolarTermInfo(
            name: '雨水',
            occurredAt: DateTime(2024, 2, 19),
            index: 3,
          ),
          SolarTermInfo(
            name: '惊蛰',
            occurredAt: DateTime(2024, 3, 5, 10, 23),
            index: 4,
            termMonth: 1,
          ),
          SolarTermInfo(
            name: '春分',
            occurredAt: DateTime(2024, 3, 20),
            index: 5,
          ),
        ],
      );
      expect(cycles, hasLength(10));
    });

    test('甲年阳男顺排 → 第一步大运 = 丁卯', () async {
      final cycles = await calculator.calculate(
        request: request,
        calendarSnapshot: CalendarSnapshot(
          request: request,
          solarDateTime: DateTime(2024, 3, 20, 12, 0),
          lunarDate: const LunarDate(year: 2024, month: 2, day: 10, isLeapMonth: false),
          precision: CalendarPrecision.approximate,
        ),
        chart: testChart(),
        solarTerms: [
          SolarTermInfo(
            name: '惊蛰',
            occurredAt: DateTime(2024, 3, 5, 10, 23),
            index: 4,
            termMonth: 1,
          ),
          SolarTermInfo(
            name: '春分',
            occurredAt: DateTime(2024, 3, 20),
            index: 5,
          ),
          SolarTermInfo(
            name: '清明',
            occurredAt: DateTime(2024, 4, 4),
            index: 6,
            termMonth: 2,
          ),
        ],
      );
      expect(cycles, hasLength(10));
      expect(cycles.first.ganZhi, '丁卯');
      expect(cycles[1].ganZhi, '戊辰');
    });

    test('十年运势均有大运干支和十神', () async {
      final cycles = await calculator.calculate(
        request: request,
        calendarSnapshot: CalendarSnapshot(
          request: request,
          solarDateTime: DateTime(2024, 3, 20),
          lunarDate: const LunarDate(year: 2024, month: 2, day: 10, isLeapMonth: false),
          precision: CalendarPrecision.approximate,
        ),
        chart: testChart(),
        solarTerms: [
          SolarTermInfo(
            name: '惊蛰',
            occurredAt: DateTime(2024, 3, 5, 10, 23),
            index: 4,
            termMonth: 1,
          ),
          SolarTermInfo(
            name: '春分',
            occurredAt: DateTime(2024, 3, 20),
            index: 5,
          ),
          SolarTermInfo(
            name: '清明',
            occurredAt: DateTime(2024, 4, 4),
            index: 6,
            termMonth: 2,
          ),
        ],
      );
      for (final cycle in cycles) {
        expect(cycle.ganZhi, isNotEmpty);
        expect(cycle.tenGod, isNotEmpty);
        expect(cycle.startAge, lessThanOrEqualTo(cycle.endAge));
        expect(cycle.startYear, lessThanOrEqualTo(cycle.endYear));
        expect(cycle.flowingYears, hasLength(10));
      }
    });

    test('起运岁数 >= 0', () async {
      final cycles = await calculator.calculate(
        request: request,
        calendarSnapshot: CalendarSnapshot(
          request: request,
          solarDateTime: DateTime(2024, 3, 20),
          lunarDate: const LunarDate(year: 2024, month: 2, day: 10, isLeapMonth: false),
          precision: CalendarPrecision.approximate,
        ),
        chart: testChart(),
        solarTerms: [
          SolarTermInfo(
            name: '惊蛰',
            occurredAt: DateTime(2024, 3, 5, 10, 23),
            index: 4,
            termMonth: 1,
          ),
          SolarTermInfo(
            name: '春分',
            occurredAt: DateTime(2024, 3, 20),
            index: 5,
          ),
          SolarTermInfo(
            name: '清明',
            occurredAt: DateTime(2024, 4, 4),
            index: 6,
            termMonth: 2,
          ),
        ],
      );
      expect(cycles.first.startAge, greaterThanOrEqualTo(0));
    });

    test('每步大运跨 10 年', () async {
      final cycles = await calculator.calculate(
        request: request,
        calendarSnapshot: CalendarSnapshot(
          request: request,
          solarDateTime: DateTime(2024, 3, 20),
          lunarDate: const LunarDate(year: 2024, month: 2, day: 10, isLeapMonth: false),
          precision: CalendarPrecision.approximate,
        ),
        chart: testChart(),
        solarTerms: [
          SolarTermInfo(
            name: '惊蛰',
            occurredAt: DateTime(2024, 3, 5, 10, 23),
            index: 4,
            termMonth: 1,
          ),
          SolarTermInfo(
            name: '春分',
            occurredAt: DateTime(2024, 3, 20),
            index: 5,
          ),
          SolarTermInfo(
            name: '清明',
            occurredAt: DateTime(2024, 4, 4),
            index: 6,
            termMonth: 2,
          ),
        ],
      );
      for (final cycle in cycles) {
        expect(cycle.endYear - cycle.startYear, 9);
        expect(cycle.endAge - cycle.startAge, 9);
      }
    });

    test('相邻大运干支连续（甲年丙寅月顺排十步）', () async {
      final cycles = await calculator.calculate(
        request: request,
        calendarSnapshot: CalendarSnapshot(
          request: request,
          solarDateTime: DateTime(2024, 3, 20),
          lunarDate: const LunarDate(year: 2024, month: 2, day: 10, isLeapMonth: false),
          precision: CalendarPrecision.approximate,
        ),
        chart: testChart(),
        solarTerms: [
          SolarTermInfo(
            name: '惊蛰',
            occurredAt: DateTime(2024, 3, 5, 10, 23),
            index: 4,
            termMonth: 1,
          ),
          SolarTermInfo(
            name: '春分',
            occurredAt: DateTime(2024, 3, 20),
            index: 5,
          ),
          SolarTermInfo(
            name: '清明',
            occurredAt: DateTime(2024, 4, 4),
            index: 6,
            termMonth: 2,
          ),
        ],
      );
      const expected = [
        '丁卯', '戊辰', '己巳', '庚午', '辛未',
        '壬申', '癸酉', '甲戌', '乙亥', '丙子',
      ];
      for (int i = 0; i < 10; i++) {
        expect(cycles[i].ganZhi, expected[i]);
      }
    });

    test('流年干支连续 10 年', () async {
      final cycles = await calculator.calculate(
        request: request,
        calendarSnapshot: CalendarSnapshot(
          request: request,
          solarDateTime: DateTime(2024, 3, 20),
          lunarDate: const LunarDate(year: 2024, month: 2, day: 10, isLeapMonth: false),
          precision: CalendarPrecision.approximate,
        ),
        chart: testChart(),
        solarTerms: [
          SolarTermInfo(
            name: '惊蛰',
            occurredAt: DateTime(2024, 3, 5, 10, 23),
            index: 4,
            termMonth: 1,
          ),
          SolarTermInfo(
            name: '春分',
            occurredAt: DateTime(2024, 3, 20),
            index: 5,
          ),
          SolarTermInfo(
            name: '清明',
            occurredAt: DateTime(2024, 4, 4),
            index: 6,
            termMonth: 2,
          ),
        ],
      );
      for (int i = 0; i < 10; i++) {
        expect(cycles.first.flowingYears[i].ganZhi, isNotEmpty);
        expect(cycles.first.flowingYears[i].tenGod, isNotEmpty);
        expect(cycles.first.flowingYears[i].year,
            cycles.first.startYear + i);
      }
    });
  });
}
