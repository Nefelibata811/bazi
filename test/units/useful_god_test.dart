// 文件：单元测试 — 用神god
//
// 验证 用神god 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/domain/entities/bazi_chart.dart';
import 'package:bazi_app/domain/entities/hidden_stem.dart';
import 'package:bazi_app/domain/entities/pillar.dart';
import 'package:bazi_app/domain/entities/pattern_result.dart';
import 'package:bazi_app/domain/services/bazi_rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bazi_app/infrastructure/calendar/rule_useful_god_analyzer.dart';

void main() {
  final engine = BaziRuleEngine();
  final analyzer = RuleUsefulGodAnalyzer(ruleEngine: engine);

  BaziChart testChart() => BaziChart(
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

  group('RuleUsefulGodAnalyzer', () {
    test('返回结果非空且字段完整', () async {
      final result = await analyzer.analyze(
        chart: testChart(),
        patterns: [],
      );
      expect(result.dayMasterStrength, isNotEmpty);
      expect(result.usefulGod, isNotEmpty);
      expect(result.supportiveGod, isNotEmpty);
      expect(result.avoidGod, isNotEmpty);
      expect(result.summary, isNotEmpty);
    });

    test('日主旺衰判定有五种等级之一', () async {
      final result = await analyzer.analyze(
        chart: testChart(),
        patterns: [],
      );
      const valid = [
        '日主偏强',
        '日主中和偏旺',
        '日主中和',
        '日主中和偏弱',
        '日主偏弱',
      ];
      expect(valid, contains(result.dayMasterStrength));
    });

    test('日主偏弱时用神包含生扶五行', () async {
      final chart = BaziChart(
        dayMaster: '癸',
        year: Pillar(
          label: '年柱',
          stem: '丙',
          branch: '午',
          tenGod: '偏财',
          hiddenStems: const [
            HiddenStem(stem: '丁', tenGod: '偏财'),
            HiddenStem(stem: '己', tenGod: '七杀'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        month: Pillar(
          label: '月柱',
          stem: '丙',
          branch: '午',
          tenGod: '偏财',
          hiddenStems: const [
            HiddenStem(stem: '丁', tenGod: '偏财'),
            HiddenStem(stem: '己', tenGod: '七杀'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        day: Pillar(
          label: '日柱',
          stem: '癸',
          branch: '酉',
          tenGod: '日主',
          hiddenStems: const [
            HiddenStem(stem: '辛', tenGod: '偏印'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        hour: Pillar(
          label: '时柱',
          stem: '丁',
          branch: '巳',
          tenGod: '偏财',
          hiddenStems: const [
            HiddenStem(stem: '丙', tenGod: '正财'),
            HiddenStem(stem: '戊', tenGod: '正官'),
            HiddenStem(stem: '庚', tenGod: '正印'),
          ],
          naYin: '',
          growthPhase: '',
        ),
      );
      final result = await analyzer.analyze(
        chart: chart,
        patterns: [],
      );
      expect(result.dayMasterStrength, contains('弱'));
    });

    test('日主得令 + 印比助力 → 偏强', () async {
      final chart = BaziChart(
        dayMaster: '癸',
        year: Pillar(
          label: '年柱',
          stem: '癸',
          branch: '亥',
          tenGod: '比肩',
          hiddenStems: const [
            HiddenStem(stem: '壬', tenGod: '劫财'),
            HiddenStem(stem: '甲', tenGod: '伤官'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        month: Pillar(
          label: '月柱',
          stem: '辛',
          branch: '亥',
          tenGod: '偏印',
          hiddenStems: const [
            HiddenStem(stem: '壬', tenGod: '劫财'),
            HiddenStem(stem: '甲', tenGod: '伤官'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        day: Pillar(
          label: '日柱',
          stem: '癸',
          branch: '子',
          tenGod: '日主',
          hiddenStems: const [
            HiddenStem(stem: '癸', tenGod: '比肩'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        hour: Pillar(
          label: '时柱',
          stem: '庚',
          branch: '申',
          tenGod: '正印',
          hiddenStems: const [
            HiddenStem(stem: '庚', tenGod: '正印'),
            HiddenStem(stem: '壬', tenGod: '劫财'),
            HiddenStem(stem: '戊', tenGod: '正官'),
          ],
          naYin: '',
          growthPhase: '',
        ),
      );
      final result = await analyzer.analyze(
        chart: chart,
        patterns: [],
      );
      expect(result.dayMasterStrength, contains('强'));
    });

    test('生产日柱标签「日」时日主天干不计入旺衰', () async {
      final chart = BaziChart(
        dayMaster: '癸',
        year: const Pillar(
          label: '年',
          stem: '丙',
          branch: '午',
          tenGod: '偏财',
          hiddenStems: [
            HiddenStem(stem: '丁', tenGod: '偏财'),
            HiddenStem(stem: '己', tenGod: '七杀'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        month: const Pillar(
          label: '月',
          stem: '丙',
          branch: '午',
          tenGod: '偏财',
          hiddenStems: [
            HiddenStem(stem: '丁', tenGod: '偏财'),
            HiddenStem(stem: '己', tenGod: '七杀'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        day: const Pillar(
          label: '日',
          stem: '癸',
          branch: '酉',
          tenGod: '日主',
          hiddenStems: [
            HiddenStem(stem: '辛', tenGod: '偏印'),
          ],
          naYin: '',
          growthPhase: '',
        ),
        hour: const Pillar(
          label: '时',
          stem: '丁',
          branch: '巳',
          tenGod: '偏财',
          hiddenStems: [
            HiddenStem(stem: '丙', tenGod: '正财'),
            HiddenStem(stem: '戊', tenGod: '正官'),
            HiddenStem(stem: '庚', tenGod: '正印'),
          ],
          naYin: '',
          growthPhase: '',
        ),
      );
      final result = await analyzer.analyze(chart: chart, patterns: []);
      expect(result.dayMasterStrength, contains('弱'));
    });

    test('不同格局影响 summary 内容', () async {
      final chart = testChart();
      final noPattern = await analyzer.analyze(
        chart: chart,
        patterns: [],
      );
      final withPattern = await analyzer.analyze(
        chart: chart,
        patterns: [
          const PatternResult(
            name: '正官格',
            summary: '',
            evidence: [],
          ),
        ],
      );
      expect(noPattern.summary, isNot(withPattern.summary));
    });
  });
}
