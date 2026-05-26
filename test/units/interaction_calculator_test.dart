import 'package:bazi_app/domain/entities/bazi_chart.dart';
import 'package:bazi_app/domain/entities/hidden_stem.dart';
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

    test('申子半合水（非申辰拱）', () {
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
      expect(
        results.any((r) => r.type == InteractionType.branchArch),
        isFalse,
      );
    });

    test('申辰拱子水', () {
      final chart = BaziChart(
        dayMaster: '甲',
        year: _p('年', '甲', '申'),
        month: _p('月', '丙', '辰'),
        day: _p('日', '戊', '申'),
        hour: _p('时', '庚', '辰'),
      );
      final results = calc.calculate(chart);
      final arch = results.where((r) => r.type == InteractionType.branchArch);
      expect(arch.length, 1);
      expect(arch.first.description, contains('申辰拱'));
    });

    test('申亥相害只显示一条', () {
      final chart = BaziChart(
        dayMaster: '甲',
        year: _p('年', '甲', '申'),
        month: _p('月', '丙', '亥'),
        day: _p('日', '戊', '申'),
        hour: _p('时', '庚', '亥'),
      );
      final results = calc.calculate(chart);
      final harm = results.where((r) => r.type == InteractionType.branchHarm6);
      expect(harm.length, 1);
      expect(harm.first.description, contains('申亥相害'));
    });

    test('有三合时不报半合与拱', () {
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
      expect(
        results.any((r) => r.type == InteractionType.branchArch),
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

    test('寅卯辰三会木', () {
      final chart = BaziChart(
        dayMaster: '甲',
        year: _p('年', '甲', '寅'),
        month: _p('月', '丙', '卯'),
        day: _p('日', '戊', '辰'),
        hour: _p('时', '庚', '午'),
      );
      final results = calc.calculate(chart);
      expect(
        results.any((r) => r.type == InteractionType.branchCombineMeet3),
        isTrue,
      );
    });

    test('子酉相破', () {
      final chart = BaziChart(
        dayMaster: '甲',
        year: _p('年', '甲', '子'),
        month: _p('月', '丙', '酉'),
        day: _p('日', '戊', '寅'),
        hour: _p('时', '庚', '卯'),
      );
      final results = calc.calculate(chart);
      expect(
        results.any((r) => r.type == InteractionType.branchBreak),
        isTrue,
      );
    });

    test('辰辰自刑', () {
      final chart = BaziChart(
        dayMaster: '甲',
        year: _p('年', '甲', '辰'),
        month: _p('月', '丙', '辰'),
        day: _p('日', '戊', '寅'),
        hour: _p('时', '庚', '卯'),
      );
      final results = calc.calculate(chart);
      expect(
        results.any((r) => r.type == InteractionType.branchSelfPunish),
        isTrue,
      );
    });

    test('甲子庚午反吟（合并天克地冲，不含单项冲）', () {
      final chart = BaziChart(
        dayMaster: '甲',
        year: _p('年', '甲', '子'),
        month: _p('月', '丙', '丑'),
        day: _p('日', '庚', '午'),
        hour: _p('时', '壬', '寅'),
      );
      final results = calc.calculate(chart);
      expect(
        results.any((r) => r.type == InteractionType.fanYin),
        isTrue,
      );
      expect(
        results.any((r) => r.type == InteractionType.stemBranchBothClash),
        isFalse,
      );
      expect(
        results.any(
          (r) =>
              r.type == InteractionType.stemClash &&
              ((r.nodeA.startsWith('年') && r.nodeB.startsWith('日')) ||
                  (r.nodeA.startsWith('日') && r.nodeB.startsWith('年'))),
        ),
        isFalse,
      );
      expect(
        results.any(
          (r) =>
              r.type == InteractionType.branchClash6 &&
              ((r.nodeA.startsWith('年') && r.nodeB.startsWith('日')) ||
                  (r.nodeA.startsWith('日') && r.nodeB.startsWith('年'))),
        ),
        isFalse,
      );
    });

    test('辅宫不参与刑冲合害（仅本命四柱）', () {
      final chart = BaziChart(
        dayMaster: '甲',
        year: _p('年', '甲', '子'),
        month: _p('月', '丙', '寅'),
        day: _p('日', '戊', '卯'),
        hour: _p('时', '庚', '辰'),
        extraPillars: [
          _p('命宫', '壬', '午'),
        ],
      );
      final results = calc.calculate(chart);
      expect(
        results.any(
          (r) => r.nodeA.contains('命宫') || r.nodeB.contains('命宫'),
        ),
        isFalse,
      );
      expect(
        results.any((r) => r.type == InteractionType.branchClash6),
        isFalse,
      );
    });

    test('藏干与透干五合（甲己）', () {
      final chart = BaziChart(
        dayMaster: '甲',
        year: _p('年', '甲', '子'),
        month: Pillar(
          label: '月',
          stem: '丙',
          branch: '丑',
          tenGod: '',
          hiddenStems: const [HiddenStem(stem: '己', tenGod: '正财')],
          naYin: '',
          growthPhase: '',
        ),
        day: _p('日', '甲', '午'),
        hour: _p('时', '壬', '寅'),
      );
      final hidden = calc.calculateHiddenStemInteractions(chart);
      final wuGui = hidden.where(
        (r) =>
            r.type == InteractionType.stemCombine &&
            r.description.contains('戊癸'),
      );
      expect(wuGui.length, lessThanOrEqualTo(1));
      expect(
        hidden.any(
          (r) =>
              r.type == InteractionType.stemCombine &&
              r.description.contains('藏干'),
        ),
        isTrue,
      );
    });
  });
}