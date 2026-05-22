import 'package:bazi_app/domain/entities/bazi_chart.dart';
import 'package:bazi_app/domain/entities/pillar.dart';
import 'package:bazi_app/infrastructure/calendar/rule_shensha_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = RuleShenshaCalculator();

  // 甲辰年（年支辰）、癸未日（日支未）
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
          branch: '亥',
          tenGod: '偏印',
          hiddenStems: [],
          naYin: '',
          growthPhase: '',
        ),
      );

  group('RuleShenshaCalculator', () {
    test('返回结果非空', () async {
      final items = await calculator.calculate(testChart());
      expect(items, isNotEmpty);
    });

    test('日干癸 年干甲 → 年干甲见未为天乙贵人 → 日支未应出', () async {
      final items = await calculator.calculate(testChart());
      final tianYi = items.where((i) => i.name == '天乙贵人');
      expect(tianYi, isNotEmpty);
      expect(tianYi.any((i) => i.target.contains('未')), isTrue);
    });

    test('日干甲 → 年柱或日柱见丑/未应有天乙贵人', () async {
      final chart = BaziChart(
        dayMaster: '甲',
        year: Pillar(
          label: '年柱',
          stem: '甲',
          branch: '丑',
          tenGod: '',
          hiddenStems: const [],
          naYin: '',
          growthPhase: '',
        ),
        month: Pillar(
          label: '月柱',
          stem: '丙',
          branch: '寅',
          tenGod: '',
          hiddenStems: const [],
          naYin: '',
          growthPhase: '',
        ),
        day: Pillar(
          label: '日柱',
          stem: '甲',
          branch: '子',
          tenGod: '日主',
          hiddenStems: const [],
          naYin: '',
          growthPhase: '',
        ),
        hour: Pillar(
          label: '时柱',
          stem: '辛',
          branch: '酉',
          tenGod: '',
          hiddenStems: const [],
          naYin: '',
          growthPhase: '',
        ),
      );
      final items = await calculator.calculate(chart);
      final tianYi = items.where((i) => i.name == '天乙贵人');
      expect(tianYi, isNotEmpty);
      expect(tianYi.first.target, contains('丑'));
    });

    test('年支辰 → 驿马在寅 → 月支寅 → 应出驿马', () async {
      final items = await calculator.calculate(testChart());
      final yiMa = items.where((i) => i.name == '驿马' && i.target.contains('寅'));
      expect(yiMa, isNotEmpty);
    });

    test('日支未 → 桃花在子 → 四柱无子 → 不出桃花', () async {
      final items = await calculator.calculate(testChart());
      final taoHua = items.where((i) => i.name == '桃花');
      expect(taoHua, isEmpty);
    });

    test('日支未 → 华盖在未 → 日柱未 → 应出华盖', () async {
      final items = await calculator.calculate(testChart());
      final huaGai = items.where((i) => i.name == '华盖' && i.target.contains('日柱'));
      expect(huaGai, isNotEmpty);
    });

    test('每个神煞都有 name / target / description', () async {
      final items = await calculator.calculate(testChart());
      for (final item in items) {
        expect(item.name, isNotEmpty);
        expect(item.target, isNotEmpty);
        expect(item.description, isNotEmpty);
      }
    });

    test('神煞数量合理（3-60 项之间）', () async {
      final items = await calculator.calculate(testChart());
      expect(items.length, greaterThanOrEqualTo(3));
      expect(items.length, lessThanOrEqualTo(60));
    });
  });
}
