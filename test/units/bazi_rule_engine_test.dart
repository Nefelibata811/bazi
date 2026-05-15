import 'package:bazi_app/domain/services/bazi_rule_engine.dart';
import 'package:bazi_app/domain/value_objects/five_element.dart';
import 'package:bazi_app/domain/value_objects/yin_yang.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = const BaziRuleEngine();

  group('BaziRuleEngine - 天干基础', () {
    test('天干共 10 个', () {
      expect(BaziRuleEngine.stems, hasLength(10));
    });

    test('天干顺序正确（甲→癸）', () {
      expect(BaziRuleEngine.stems, ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸']);
    });

    test('天干五行映射正确', () {
      final wood = [FiveElement.wood, FiveElement.wood];
      final fire = [FiveElement.fire, FiveElement.fire];
      final earth = [FiveElement.earth, FiveElement.earth];
      final metal = [FiveElement.metal, FiveElement.metal];
      final water = [FiveElement.water, FiveElement.water];

      expect(BaziRuleEngine.stems.map(engine.stemElementOf),
          [...wood, ...fire, ...earth, ...metal, ...water]);
    });

    test('天干阴阳映射正确（单数阳双数阴）', () {
      expect(engine.stemPolarityOf('甲'), YinYang.yang);
      expect(engine.stemPolarityOf('乙'), YinYang.yin);
      expect(engine.stemPolarityOf('丙'), YinYang.yang);
      expect(engine.stemPolarityOf('丁'), YinYang.yin);
      expect(engine.stemPolarityOf('戊'), YinYang.yang);
      expect(engine.stemPolarityOf('己'), YinYang.yin);
      expect(engine.stemPolarityOf('庚'), YinYang.yang);
      expect(engine.stemPolarityOf('辛'), YinYang.yin);
      expect(engine.stemPolarityOf('壬'), YinYang.yang);
      expect(engine.stemPolarityOf('癸'), YinYang.yin);
    });
  });

  group('BaziRuleEngine - 地支基础', () {
    test('地支共 12 个', () {
      expect(BaziRuleEngine.branches, hasLength(12));
    });

    test('地支顺序正确（子→亥）', () {
      expect(BaziRuleEngine.branches,
          ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥']);
    });
  });

  group('BaziRuleEngine - 十神判定', () {
    // 以癸水为日主，测全十天干十神。
    // 癸属阴水 → 壬（阳水）= 劫财，癸（阴水）= 比肩
    // 庚（阳金）= 正印（生癸水），辛（阴金）= 偏印
    // 乙（阴木）= 食神（癸水生），甲（阳木）= 伤官
    // 丙（阳火）= 正财（癸克），丁（阴火）= 偏财
    // 戊（阳土）= 正官（克癸），己（阴土）= 七杀
    test('癸日主 → 甲为伤官', () {
      expect(engine.tenGodFor(dayMasterStem: '癸', targetStem: '甲'), '伤官');
    });

    test('癸日主 → 乙为食神', () {
      expect(engine.tenGodFor(dayMasterStem: '癸', targetStem: '乙'), '食神');
    });

    test('癸日主 → 丙为正财', () {
      expect(engine.tenGodFor(dayMasterStem: '癸', targetStem: '丙'), '正财');
    });

    test('癸日主 → 丁为偏财', () {
      expect(engine.tenGodFor(dayMasterStem: '癸', targetStem: '丁'), '偏财');
    });

    test('癸日主 → 戊为正官', () {
      expect(engine.tenGodFor(dayMasterStem: '癸', targetStem: '戊'), '正官');
    });

    test('癸日主 → 己为七杀', () {
      expect(engine.tenGodFor(dayMasterStem: '癸', targetStem: '己'), '七杀');
    });

    test('癸日主 → 庚为正印', () {
      expect(engine.tenGodFor(dayMasterStem: '癸', targetStem: '庚'), '正印');
    });

    test('癸日主 → 辛为偏印', () {
      expect(engine.tenGodFor(dayMasterStem: '癸', targetStem: '辛'), '偏印');
    });

    test('癸日主 → 壬为劫财', () {
      expect(engine.tenGodFor(dayMasterStem: '癸', targetStem: '壬'), '劫财');
    });

    test('癸日主 → 癸为比肩', () {
      expect(engine.tenGodFor(dayMasterStem: '癸', targetStem: '癸'), '比肩');
    });

    // 以甲木（阳木）为日主验证阴阳逻辑。
    test('甲日主 → 甲为比肩（同阳）', () {
      expect(engine.tenGodFor(dayMasterStem: '甲', targetStem: '甲'), '比肩');
    });

    test('甲日主 → 乙为劫财（同五行异阴阳）', () {
      expect(engine.tenGodFor(dayMasterStem: '甲', targetStem: '乙'), '劫财');
    });

    test('甲日主 → 丙为食神（甲生丙，同阳）', () {
      expect(engine.tenGodFor(dayMasterStem: '甲', targetStem: '丙'), '食神');
    });

    test('甲日主 → 丁为伤官（甲生丁，异阴阳）', () {
      expect(engine.tenGodFor(dayMasterStem: '甲', targetStem: '丁'), '伤官');
    });

    test('甲日主 → 戊为偏财（甲克戊，同阳）', () {
      expect(engine.tenGodFor(dayMasterStem: '甲', targetStem: '戊'), '偏财');
    });

    test('甲日主 → 己为正财（甲克己，异阴阳）', () {
      expect(engine.tenGodFor(dayMasterStem: '甲', targetStem: '己'), '正财');
    });

    test('甲日主 → 庚为七杀（庚克甲，同阳）', () {
      expect(engine.tenGodFor(dayMasterStem: '甲', targetStem: '庚'), '七杀');
    });

    test('甲日主 → 辛为正官（辛克甲，异阴阳）', () {
      expect(engine.tenGodFor(dayMasterStem: '甲', targetStem: '辛'), '正官');
    });

    test('甲日主 → 壬为偏印（壬生甲，同阳）', () {
      expect(engine.tenGodFor(dayMasterStem: '甲', targetStem: '壬'), '偏印');
    });

    test('甲日主 → 癸为正印（癸生甲，异阴阳）', () {
      expect(engine.tenGodFor(dayMasterStem: '甲', targetStem: '癸'), '正印');
    });
  });

  group('BaziRuleEngine - 地支藏干', () {
    test('子藏癸', () {
      expect(engine.hiddenStemsOf('子').map((h) => h.stem), ['癸']);
    });

    test('丑藏己癸辛', () {
      expect(engine.hiddenStemsOf('丑').map((h) => h.stem), ['己', '癸', '辛']);
    });

    test('寅藏甲丙戊', () {
      expect(engine.hiddenStemsOf('寅').map((h) => h.stem), ['甲', '丙', '戊']);
    });

    test('卯藏乙', () {
      expect(engine.hiddenStemsOf('卯').map((h) => h.stem), ['乙']);
    });

    test('午藏丁己', () {
      expect(engine.hiddenStemsOf('午').map((h) => h.stem), ['丁', '己']);
    });

    test('所有十二地支都有藏干结果', () {
      for (final branch in BaziRuleEngine.branches) {
        final hidden = engine.hiddenStemsOf(branch);
        expect(hidden, isNotEmpty,
            reason: '$branch 藏干不应为空');
      }
    });
  });

  group('BaziRuleEngine - 纳音', () {
    test('甲子乙丑 → 海中金', () {
      expect(engine.naYinOf(stem: '甲', branch: '子'), '海中金');
      expect(engine.naYinOf(stem: '乙', branch: '丑'), '海中金');
    });

    test('丙寅丁卯 → 炉中火', () {
      expect(engine.naYinOf(stem: '丙', branch: '寅'), '炉中火');
    });

    test('戊辰己巳 → 大林木', () {
      expect(engine.naYinOf(stem: '戊', branch: '辰'), '大林木');
    });

    test('壬戌癸亥 → 大海水', () {
      expect(engine.naYinOf(stem: '壬', branch: '戌'), '大海水');
      expect(engine.naYinOf(stem: '癸', branch: '亥'), '大海水');
    });

    test('所有六十甲子纳音都可查询', () {
      for (int i = 0; i < 60; i++) {
        final stem = BaziRuleEngine.stems[i % 10];
        final branch = BaziRuleEngine.branches[i % 12];
        final naYin = engine.naYinOf(stem: stem, branch: branch);
        expect(naYin, isNotEmpty);
        expect(naYin, isNot('未知'));
      }
    });
  });

  group('BaziRuleEngine - 十二长生', () {
    test('癸日主地支长生表', () {
      // 癸水 → 卯（长生）、寅（沐浴）、丑（冠带）、……等
      expect(engine.growthPhaseOf(stem: '癸', branch: '卯'), '长生');
    });

    test('甲日主地支长生表', () {
      // 甲木 → 亥（长生）
      expect(engine.growthPhaseOf(stem: '甲', branch: '亥'), '长生');
    });

    test('庚日主地支长生表', () {
      // 庚金 → 巳（长生）
      expect(engine.growthPhaseOf(stem: '庚', branch: '巳'), '长生');
    });

    test('所有长生查询不返回空', () {
      for (final stem in BaziRuleEngine.stems) {
        for (final branch in BaziRuleEngine.branches) {
          final phase = engine.growthPhaseOf(stem: stem, branch: branch);
          expect(phase, isNotEmpty);
        }
      }
    });

    test('癸水长生在卯', () {
      expect(engine.growthPhaseOf(stem: '癸', branch: '卯'), '长生');
    });

    test('癸水绝在午', () {
      expect(engine.growthPhaseOf(stem: '癸', branch: '午'), '绝');
    });
  });
}
