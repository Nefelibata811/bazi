// 八字规则引擎：十神、藏干、纳音、十二长生等查表与推算（无 UI、无网络）。
// 排盘主数据来自 lunar 库，本类补充规则层；详见 docs/ALGORITHMS.md。
import '../entities/hidden_stem.dart';
import '../entities/pillar.dart';
import '../value_objects/five_element.dart';
import '../value_objects/yin_yang.dart';

/// 纯 Dart 规则表与计算方法，供 [LunarBaziCalculator] 等基础设施调用。
class BaziRuleEngine {
  const BaziRuleEngine();

  static const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  static const branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  static const growthPhases = [
    '长生',
    '沐浴',
    '冠带',
    '临官',
    '帝旺',
    '衰',
    '病',
    '死',
    '墓',
    '绝',
    '胎',
    '养',
  ];

  static const Map<String, FiveElement> _stemElements = {
    '甲': FiveElement.wood,
    '乙': FiveElement.wood,
    '丙': FiveElement.fire,
    '丁': FiveElement.fire,
    '戊': FiveElement.earth,
    '己': FiveElement.earth,
    '庚': FiveElement.metal,
    '辛': FiveElement.metal,
    '壬': FiveElement.water,
    '癸': FiveElement.water,
  };

  static const Map<String, YinYang> _stemPolarity = {
    '甲': YinYang.yang,
    '乙': YinYang.yin,
    '丙': YinYang.yang,
    '丁': YinYang.yin,
    '戊': YinYang.yang,
    '己': YinYang.yin,
    '庚': YinYang.yang,
    '辛': YinYang.yin,
    '壬': YinYang.yang,
    '癸': YinYang.yin,
  };

  static const Map<String, List<String>> _hiddenStemMap = {
    '子': ['癸'],
    '丑': ['己', '癸', '辛'],
    '寅': ['甲', '丙', '戊'],
    '卯': ['乙'],
    '辰': ['戊', '乙', '癸'],
    '巳': ['丙', '戊', '庚'],
    '午': ['丁', '己'],
    '未': ['己', '丁', '乙'],
    '申': ['庚', '壬', '戊'],
    '酉': ['辛'],
    '戌': ['戊', '辛', '丁'],
    '亥': ['壬', '甲'],
  };

  static const Map<String, String> _naYinMap = {
    '甲子': '海中金',
    '乙丑': '海中金',
    '丙寅': '炉中火',
    '丁卯': '炉中火',
    '戊辰': '大林木',
    '己巳': '大林木',
    '庚午': '路旁土',
    '辛未': '路旁土',
    '壬申': '剑锋金',
    '癸酉': '剑锋金',
    '甲戌': '山头火',
    '乙亥': '山头火',
    '丙子': '涧下水',
    '丁丑': '涧下水',
    '戊寅': '城头土',
    '己卯': '城头土',
    '庚辰': '白蜡金',
    '辛巳': '白蜡金',
    '壬午': '杨柳木',
    '癸未': '杨柳木',
    '甲申': '泉中水',
    '乙酉': '泉中水',
    '丙戌': '屋上土',
    '丁亥': '屋上土',
    '戊子': '霹雳火',
    '己丑': '霹雳火',
    '庚寅': '松柏木',
    '辛卯': '松柏木',
    '壬辰': '长流水',
    '癸巳': '长流水',
    '甲午': '砂中金',
    '乙未': '砂中金',
    '丙申': '山下火',
    '丁酉': '山下火',
    '戊戌': '平地木',
    '己亥': '平地木',
    '庚子': '壁上土',
    '辛丑': '壁上土',
    '壬寅': '金箔金',
    '癸卯': '金箔金',
    '甲辰': '覆灯火',
    '乙巳': '覆灯火',
    '丙午': '天河水',
    '丁未': '天河水',
    '戊申': '大驿土',
    '己酉': '大驿土',
    '庚戌': '钗钏金',
    '辛亥': '钗钏金',
    '壬子': '桑柘木',
    '癸丑': '桑柘木',
    '甲寅': '大溪水',
    '乙卯': '大溪水',
    '丙辰': '沙中土',
    '丁巳': '沙中土',
    '戊午': '天上火',
    '己未': '天上火',
    '庚申': '石榴木',
    '辛酉': '石榴木',
    '壬戌': '大海水',
    '癸亥': '大海水',
  };

  static const Map<String, List<String>> _growthPhaseSequence = {
    '甲': ['亥', '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌'],
    '乙': ['午', '巳', '辰', '卯', '寅', '丑', '子', '亥', '戌', '酉', '申', '未'],
    '丙': ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'],
    '丁': ['酉', '申', '未', '午', '巳', '辰', '卯', '寅', '丑', '子', '亥', '戌'],
    '戊': ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'],
    '己': ['酉', '申', '未', '午', '巳', '辰', '卯', '寅', '丑', '子', '亥', '戌'],
    '庚': ['巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑', '寅', '卯', '辰'],
    '辛': ['子', '亥', '戌', '酉', '申', '未', '午', '巳', '辰', '卯', '寅', '丑'],
    '壬': ['申', '酉', '戌', '亥', '子', '丑', '寅', '卯', '辰', '巳', '午', '未'],
    '癸': ['卯', '寅', '丑', '子', '亥', '戌', '酉', '申', '未', '午', '巳', '辰'],
  };

  FiveElement stemElementOf(String stem) {
    return _stemElements[stem] ?? (throw ArgumentError('未知天干: $stem'));
  }

  YinYang stemPolarityOf(String stem) {
    return _stemPolarity[stem] ?? (throw ArgumentError('未知天干: $stem'));
  }

  String tenGodFor({
    required String dayMasterStem,
    required String targetStem,
  }) {
    if (dayMasterStem == targetStem) {
      return '比肩';
    }

    final selfElement = stemElementOf(dayMasterStem);
    final targetElement = stemElementOf(targetStem);
    final samePolarity = stemPolarityOf(dayMasterStem) == stemPolarityOf(targetStem);

    if (selfElement == targetElement) {
      return samePolarity ? '比肩' : '劫财';
    }

    // 十神判定的核心是“五行关系 + 阴阳同异”。
    // 除比劫外，多数关系里“同阴阳偏、异阴阳正”；我生者则命名为食神/伤官。
    if (_generates(selfElement, targetElement)) {
      return samePolarity ? '食神' : '伤官';
    }

    if (_controls(selfElement, targetElement)) {
      return samePolarity ? '偏财' : '正财';
    }

    if (_controls(targetElement, selfElement)) {
      return samePolarity ? '七杀' : '正官';
    }

    if (_generates(targetElement, selfElement)) {
      return samePolarity ? '偏印' : '正印';
    }

    throw ArgumentError('无法判定十神: $dayMasterStem -> $targetStem');
  }

  List<HiddenStem> hiddenStemsFor({
    required String dayMasterStem,
    required String branch,
  }) {
    final stems = _hiddenStemMap[branch];
    if (stems == null) {
      throw ArgumentError('未知地支: $branch');
    }

    return stems
        .map(
          (stem) => HiddenStem(
            stem: stem,
            tenGod: tenGodFor(dayMasterStem: dayMasterStem, targetStem: stem),
          ),
        )
        .toList(growable: false);
  }

  String naYinFor({
    required String stem,
    required String branch,
  }) {
    final key = '$stem$branch';
    return _naYinMap[key] ?? '未知纳音';
  }

  /// 天干配五行，如 丁 → 丁火。
  String stemElementLabel(String stem) {
    final element = _stemElements[stem];
    if (element == null) return stem;
    return '$stem${element.label}';
  }

  String growthPhaseFor({
    required String dayMasterStem,
    required String branch,
  }) {
    final sequence = _growthPhaseSequence[dayMasterStem];
    if (sequence == null) {
      throw ArgumentError('未知日主天干: $dayMasterStem');
    }

    // 长生十二宫对阳干顺排、阴干逆排；这里直接固化每个天干的起点序列，
    // 让上层算法只关心“某干在某支是什么状态”。
    final phaseIndex = sequence.indexOf(branch);
    if (phaseIndex == -1) {
      throw ArgumentError('未知地支: $branch');
    }

    return growthPhases[phaseIndex];
  }

  Pillar buildPillar({
    required String label,
    required String stem,
    required String branch,
    required String dayMasterStem,
    String growthPhaseSuffix = '',
  }) {
    final tenGod = label == '日' || label == '日柱'
        ? '日主'
        : tenGodFor(dayMasterStem: dayMasterStem, targetStem: stem);

    return Pillar(
      label: label,
      stem: stem,
      branch: branch,
      tenGod: tenGod,
      hiddenStems: hiddenStemsFor(
        dayMasterStem: dayMasterStem,
        branch: branch,
      ),
      naYin: naYinFor(stem: stem, branch: branch),
      growthPhase:
          '${growthPhaseFor(dayMasterStem: dayMasterStem, branch: branch)}$growthPhaseSuffix',
      seatGrowthPhase: growthPhaseFor(dayMasterStem: stem, branch: branch),
    );
  }

  bool _generates(FiveElement source, FiveElement target) {
    return (source == FiveElement.wood && target == FiveElement.fire) ||
        (source == FiveElement.fire && target == FiveElement.earth) ||
        (source == FiveElement.earth && target == FiveElement.metal) ||
        (source == FiveElement.metal && target == FiveElement.water) ||
        (source == FiveElement.water && target == FiveElement.wood);
  }

  bool _controls(FiveElement source, FiveElement target) {
    return (source == FiveElement.wood && target == FiveElement.earth) ||
        (source == FiveElement.fire && target == FiveElement.metal) ||
        (source == FiveElement.earth && target == FiveElement.water) ||
        (source == FiveElement.metal && target == FiveElement.wood) ||
        (source == FiveElement.water && target == FiveElement.fire);
  }
}
