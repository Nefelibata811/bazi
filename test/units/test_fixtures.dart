import 'package:bazi_app/domain/entities/bazi_chart.dart';
import 'package:bazi_app/domain/entities/hidden_stem.dart';
import 'package:bazi_app/domain/entities/pillar.dart';

class TestFixtures {
  const TestFixtures._();

  // 公历 1984-02-04 18:00（立春当日，甲子年）
  static DateTime get jiaZiYearDate => DateTime(1984, 2, 4, 18, 0);

  // 公历 2024-03-05 10:23（惊蛰，甲辰年 丙寅月）
  static DateTime get jiaChenYearDate => DateTime(2024, 3, 5, 10, 23);

  // 公历 2024-06-21 00:00（夏至，甲辰年 庚午月）
  static DateTime get xiaZhi2024 => DateTime(2024, 6, 21);

  // 公历 2000-01-01 12:00（庚辰年 丙子月）
  static DateTime get gengChenYearDate => DateTime(2000, 1, 1, 12, 0);

  // 已知参考点：1900-01-01 儒略日（整数日界）≈ 2415021，甲戌日（干支序号 10）
  static DateTime get reference1900 => DateTime(1900, 1, 1);

  static const referenceJd1900 = 2415021;

  // 已知参考点：1984-01-01 儒略日 ≈ 2445701
  static DateTime get reference1984 => DateTime(1984, 1, 1);

  static HiddenStem hs(String stem, String tenGod) =>
      HiddenStem(stem: stem, tenGod: tenGod);

  Pillar pillar({
    String label = '日柱',
    required String stem,
    required String branch,
    String tenGod = '日主',
  }) {
    return Pillar(
      label: label,
      stem: stem,
      branch: branch,
      tenGod: tenGod,
      hiddenStems: const [],
      naYin: '',
      growthPhase: '',
    );
  }

  // 甲辰年 丙寅月 癸未日 辛酉时 —— 常见测试局
  BaziChart makeJiaChenChart() {
    return BaziChart(
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
        naYin: '覆灯火',
        growthPhase: '养',
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
        naYin: '炉中火',
        growthPhase: '沐浴令',
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
        naYin: '杨柳木',
        growthPhase: '墓',
      ),
      hour: const Pillar(
        label: '时柱',
        stem: '辛',
        branch: '酉',
        tenGod: '偏印',
        hiddenStems: [
          HiddenStem(stem: '辛', tenGod: '偏印'),
        ],
        naYin: '石榴木',
        growthPhase: '病',
      ),
    );
  }
}
