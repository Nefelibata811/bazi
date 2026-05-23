import 'package:bazi_app/domain/entities/bazi_chart.dart';
import 'package:bazi_app/domain/entities/interaction_result.dart';
import 'package:bazi_app/domain/entities/pillar.dart';
import 'package:bazi_app/infrastructure/calendar/interaction_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Pillar _p(String label, String stem, String branch) => Pillar(
      label: label,
      stem: stem,
      branch: branch,
      tenGod: '',
      hiddenStems: const [],
      naYin: '',
      growthPhase: '',
    );

void main() {
  const calc = BaziInteractionCalculator();

  group('BaziInteractionCalculator', () {
    test('申子辰三合水局', () {
      final chart = BaziChart(
        dayMaster: '癸',
        year: _p('年', '甲', '申'),
        month: _p('月', '丙', '子'),
        day: _p('日', '戊', '辰'),
        hour: _p('时', '庚', '午'),
      );
      final results = calc.calculate(chart);
      expect(
        results.any((r) => r.type == InteractionType.branchCombine3),
        isTrue,
      );
      final triple = results.firstWhere(
        (r) => r.type == InteractionType.branchCombine3,
      );
      expect(triple.combinedElement, '水');
      expect(triple.description, contains('申子辰'));
    });

    test('申子半合水（缺辰）', () {
      final chart = BaziChart(
        dayMaster: '甲',
        year: _p('年', '甲', '申'),
        month: _p('月', '丙', '子'),
        day: _p('日', '戊', '午'),
        hour: _p('时', '庚', '酉'),
      );
      final results = calc.calculate(chart);
      expect(
        results.any((r) => r.type == InteractionType.branchCombineHalf),
        isTrue,
      );
      final half = results.firstWhere(
        (r) => r.type == InteractionType.branchCombineHalf,
      );
      expect(half.combinedElement, '水');
      expect(half.description, contains('半合'));
    });

    test('有三合时不报半合', () {
      final chart = BaziChart(
        dayMaster: '癸',
        year: _p('年', '甲', '申'),
        month: _p('月', '丙', '子'),
        day: _p('日', '戊', '辰'),
        hour: _p('时', '庚', '辰'),
      );
      final results = calc.calculate(chart);
      expect(
        results.any((r) => r.type == InteractionType.branchCombine3),
        isTrue,
      );
      expect(
        results.any((r) => r.type == InteractionType.branchCombineHalf),
        isFalse,
      );
    });

    test('子丑六合', () {
      final chart = BaziChart(
        dayMaster: '甲',
        year: _p('年', '甲', '子'),
        month: _p('月', '丙', '丑'),
        day: _p('日', '戊', '寅'),
        hour: _p('时', '庚', '卯'),
      );
      final results = calc.calculate(chart);
      expect(
        results.any((r) => r.type == InteractionType.branchCombine6),
        isTrue,
      );
    });
  });
}
