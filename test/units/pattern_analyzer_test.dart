// 文件：单元测试 — 格局analyzer
//
// 验证 格局analyzer 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/domain/entities/bazi_chart.dart';
import 'package:bazi_app/domain/entities/hidden_stem.dart';
import 'package:bazi_app/domain/entities/pillar.dart';
import 'package:bazi_app/domain/services/bazi_rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bazi_app/infrastructure/calendar/rule_pattern_analyzer.dart';

void main() {
  final engine = BaziRuleEngine();
  final analyzer = RulePatternAnalyzer(ruleEngine: engine);

  // 癸日主，月支寅 → 格神甲木 → 癸见甲 = 伤官格
  // 月干丙火 → 透非格神 → 丙=偏财，可兼格
  BaziChart jiaChenChart() => BaziChart(
        dayMaster: '癸',
        year: const Pillar(
          label: '年柱',
          stem: '甲',
          branch: '辰',
          tenGod: '伤官',
          hiddenStems: [
            HiddenStem(stem: '戊', tenGod: '正官'),
            HiddenStem(stem: '乙', tenGod: '食神'),
            HiddenStem(stem: '癸', tenGod: '比肩'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        month: const Pillar(
          label: '月柱',
          stem: '丙',
          branch: '寅',
          tenGod: '偏财',
          hiddenStems: [
            HiddenStem(stem: '甲', tenGod: '伤官'),
            HiddenStem(stem: '丙', tenGod: '偏财'),
            HiddenStem(stem: '戊', tenGod: '正官'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        day: const Pillar(
          label: '日柱',
          stem: '癸',
          branch: '未',
          tenGod: '日主',
          hiddenStems: [
            HiddenStem(stem: '己', tenGod: '七杀'),
            HiddenStem(stem: '丁', tenGod: '正财'),
            HiddenStem(stem: '乙', tenGod: '食神'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        hour: const Pillar(
          label: '时柱',
          stem: '辛',
          branch: '酉',
          tenGod: '偏印',
          hiddenStems: [
            HiddenStem(stem: '辛', tenGod: '偏印'),
          ],
          naYin: '',
          growthPhase: '',
        ),
      );

  group('RulePatternAnalyzer', () {
    test('甲辰年丙寅月 → 月支寅 → 格神甲 → 癸日主见甲为伤官格', () async {
      final patterns = await analyzer.analyze(jiaChenChart());
      expect(patterns, isNotEmpty);
      expect(patterns.first.name, '伤官格');
    });

    test('主格置信度 > 0.2', () async {
      final patterns = await analyzer.analyze(jiaChenChart());
      expect(patterns.first.confidence, greaterThanOrEqualTo(0.2));
      expect(patterns.first.confidence, lessThanOrEqualTo(0.95));
    });

    test('兼格：月干透丙（偏财）构成兼格参考', () async {
      final patterns = await analyzer.analyze(jiaChenChart());
      final hasSecondary = patterns.any((p) => p.name.contains('兼'));
      expect(hasSecondary, isTrue);
    });

    test('格局证据列表非空', () async {
      final patterns = await analyzer.analyze(jiaChenChart());
      for (final p in patterns) {
        expect(p.evidence, isNotEmpty);
        expect(p.summary, isNotEmpty);
      }
    });

    test('月支子 → 格神癸 → 癸日主见癸为建禄格', () async {
      final chart = BaziChart(
        dayMaster: '癸',
        year: const Pillar(
          label: '年柱',
          stem: '壬',
          branch: '子',
          tenGod: '劫财',
          hiddenStems: [HiddenStem(stem: '癸', tenGod: '比肩')],
          naYin: '',
          growthPhase: '',
        ),
        month: const Pillar(
          label: '月柱',
          stem: '壬',
          branch: '子',
          tenGod: '劫财',
          hiddenStems: [HiddenStem(stem: '癸', tenGod: '比肩')],
          naYin: '',
          growthPhase: '',
        ),
        day: const Pillar(
          label: '日柱',
          stem: '癸',
          branch: '酉',
          tenGod: '日主',
          hiddenStems: [HiddenStem(stem: '辛', tenGod: '偏印')],
          naYin: '',
          growthPhase: '',
        ),
        hour: const Pillar(
          label: '时柱',
          stem: '辛',
          branch: '酉',
          tenGod: '偏印',
          hiddenStems: [HiddenStem(stem: '辛', tenGod: '偏印')],
          naYin: '',
          growthPhase: '',
        ),
      );
      final patterns = await analyzer.analyze(chart);
      expect(patterns.first.name, '建禄格');
    });

    test('月支寅 + 甲日主 → 比肩 → 建禄格', () async {
      final chart = BaziChart(
        dayMaster: '甲',
        year: const Pillar(
          label: '年柱',
          stem: '甲',
          branch: '子',
          tenGod: '比肩',
          hiddenStems: [HiddenStem(stem: '癸', tenGod: '正印')],
          naYin: '',
          growthPhase: '',
        ),
        month: const Pillar(
          label: '月柱',
          stem: '丙',
          branch: '寅',
          tenGod: '食神',
          hiddenStems: [HiddenStem(stem: '甲', tenGod: '比肩')],
          naYin: '',
          growthPhase: '',
        ),
        day: const Pillar(
          label: '日柱',
          stem: '甲',
          branch: '寅',
          tenGod: '日主',
          hiddenStems: [HiddenStem(stem: '甲', tenGod: '比肩')],
          naYin: '',
          growthPhase: '',
        ),
        hour: const Pillar(
          label: '时柱',
          stem: '甲',
          branch: '子',
          tenGod: '比肩',
          hiddenStems: [HiddenStem(stem: '癸', tenGod: '正印')],
          naYin: '',
          growthPhase: '',
        ),
      );
      final patterns = await analyzer.analyze(chart);
      expect(patterns.first.name, '建禄格');
    });

    test('官杀混杂检测', () async {
      final chart = BaziChart(
        dayMaster: '癸',
        year: const Pillar(
          label: '年柱',
          stem: '戊',
          branch: '子',
          tenGod: '正官',
          hiddenStems: [HiddenStem(stem: '癸', tenGod: '比肩')],
          naYin: '',
          growthPhase: '',
        ),
        month: const Pillar(
          label: '月柱',
          stem: '己',
          branch: '寅',
          tenGod: '七杀',
          hiddenStems: [HiddenStem(stem: '甲', tenGod: '伤官')],
          naYin: '',
          growthPhase: '',
        ),
        day: const Pillar(
          label: '日柱',
          stem: '癸',
          branch: '酉',
          tenGod: '日主',
          hiddenStems: [HiddenStem(stem: '辛', tenGod: '偏印')],
          naYin: '',
          growthPhase: '',
        ),
        hour: const Pillar(
          label: '时柱',
          stem: '辛',
          branch: '酉',
          tenGod: '偏印',
          hiddenStems: [HiddenStem(stem: '辛', tenGod: '偏印')],
          naYin: '',
          growthPhase: '',
        ),
      );
      final patterns = await analyzer.analyze(chart);
      final hasMixed = patterns.any(
        (p) => p.evidence.any(
          (e) => e.contains('官杀混杂') || e.contains('财印交加'),
        ),
      );
      expect(hasMixed, isTrue);
    });
  });
}
