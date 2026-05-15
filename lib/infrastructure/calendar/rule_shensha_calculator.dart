import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/pillar.dart';
import '../../domain/entities/shensha_item.dart';
import '../../domain/services/bazi_rule_engine.dart';
import '../../domain/services/shensha_calculator.dart';

class RuleShenshaCalculator implements ShenshaCalculator {
  const RuleShenshaCalculator({
    required BaziRuleEngine ruleEngine,
  }) : _ruleEngine = ruleEngine;

  final BaziRuleEngine _ruleEngine;

  // 天乙贵人：甲戊庚牛羊，乙己鼠猴乡，丙丁猪鸡位，壬癸兔蛇藏，六辛逢虎马
  static const _tianYiGuiRen = {
    '甲': ['丑', '未'],
    '乙': ['子', '申'],
    '丙': ['亥', '酉'],
    '丁': ['亥', '酉'],
    '戊': ['丑', '未'],
    '己': ['子', '申'],
    '庚': ['丑', '未'],
    '辛': ['寅', '午'],
    '壬': ['卯', '巳'],
    '癸': ['卯', '巳'],
  };

  // 驿马：申子辰在寅，寅午戌在申，巳酉丑在亥，亥卯未在巳
  static const _yiMa = {
    '申': '寅',
    '子': '寅',
    '辰': '寅',
    '寅': '申',
    '午': '申',
    '戌': '申',
    '巳': '亥',
    '酉': '亥',
    '丑': '亥',
    '亥': '巳',
    '卯': '巳',
    '未': '巳',
  };

  // 桃花：申子辰在酉，寅午戌在卯，巳酉丑在午，亥卯未在子
  static const _taoHua = {
    '申': '酉',
    '子': '酉',
    '辰': '酉',
    '寅': '卯',
    '午': '卯',
    '戌': '卯',
    '巳': '午',
    '酉': '午',
    '丑': '午',
    '亥': '子',
    '卯': '子',
    '未': '子',
  };

  // 华盖：申子辰在辰，寅午戌在戌，巳酉丑在丑，亥卯未在未
  static const _huaGai = {
    '申': '辰',
    '子': '辰',
    '辰': '辰',
    '寅': '戌',
    '午': '戌',
    '戌': '戌',
    '巳': '丑',
    '酉': '丑',
    '丑': '丑',
    '亥': '未',
    '卯': '未',
    '未': '未',
  };

  // 亡神：申子辰在亥，寅午戌在巳，巳酉丑在申，亥卯未在寅
  static const _wangShen = {
    '申': '亥',
    '子': '亥',
    '辰': '亥',
    '寅': '巳',
    '午': '巳',
    '戌': '巳',
    '巳': '申',
    '酉': '申',
    '丑': '申',
    '亥': '寅',
    '卯': '寅',
    '未': '寅',
  };

  // 劫煞：申子辰在巳，寅午戌在亥，巳酉丑在寅，亥卯未在申
  static const _jieSha = {
    '申': '巳',
    '子': '巳',
    '辰': '巳',
    '寅': '亥',
    '午': '亥',
    '戌': '亥',
    '巳': '寅',
    '酉': '寅',
    '丑': '寅',
    '亥': '申',
    '卯': '申',
    '未': '申',
  };

  @override
  Future<List<ShenshaItem>> calculate(BaziChart chart) async {
    final results = <ShenshaItem>[];
    final dayStem = chart.dayMaster;
    final yearBranch = chart.year.branch;
    final dayBranch = chart.day.branch;

    _checkTianYi(results, chart, dayStem);
    _checkBranchBased(results, chart, yearBranch, '年支');
    _checkBranchBased(results, chart, dayBranch, '日支');
    _checkKongWang(results, chart, dayStem);

    return results;
  }

  void _checkTianYi(
    List<ShenshaItem> results,
    BaziChart chart,
    String dayStem,
  ) {
    final guirenBranches = _tianYiGuiRen[dayStem];
    if (guirenBranches == null) return;

    for (final pillar in chart.pillars) {
      if (guirenBranches.contains(pillar.branch)) {
        results.add(ShenshaItem(
          name: '天乙贵人',
          target: '${pillar.label}支${pillar.branch}',
          description: '日干 $dayStem 见 ${pillar.branch} 为天乙贵人，主逢凶化吉、得人扶助。',
        ));
      }
    }
  }

  void _checkBranchBased(
    List<ShenshaItem> results,
    BaziChart chart,
    String baseBranch,
    String baseLabel,
  ) {
    final yiMaBranch = _yiMa[baseBranch];
    final taoHuaBranch = _taoHua[baseBranch];
    final huaGaiBranch = _huaGai[baseBranch];
    final wangShenBranch = _wangShen[baseBranch];
    final jieShaBranch = _jieSha[baseBranch];

    for (final pillar in chart.pillars) {
      if (pillar.branch == yiMaBranch) {
        results.add(ShenshaItem(
          name: '驿马',
          target: '${pillar.label}支${pillar.branch}',
          description: '$baseLabel $baseBranch 见 ${pillar.branch} 为驿马，主动荡、迁移、奔波之象。',
        ));
      }
      if (pillar.branch == taoHuaBranch) {
        results.add(ShenshaItem(
          name: '桃花',
          target: '${pillar.label}支${pillar.branch}',
          description: '$baseLabel $baseBranch 见 ${pillar.branch} 为桃花（咸池），主人缘与情感，吉凶须结合十神判断。',
        ));
      }
      if (pillar.branch == huaGaiBranch) {
        results.add(ShenshaItem(
          name: '华盖',
          target: '${pillar.label}支${pillar.branch}',
          description: '$baseLabel $baseBranch 见 ${pillar.branch} 为华盖，主学术、艺术、玄学偏才气质。',
        ));
      }
      if (pillar.branch == wangShenBranch) {
        results.add(ShenshaItem(
          name: '亡神',
          target: '${pillar.label}支${pillar.branch}',
          description: '$baseLabel $baseBranch 见 ${pillar.branch} 为亡神，主官非口舌，亦为魄力之象。',
        ));
      }
      if (pillar.branch == jieShaBranch) {
        results.add(ShenshaItem(
          name: '劫煞',
          target: '${pillar.label}支${pillar.branch}',
          description: '$baseLabel $baseBranch 见 ${pillar.branch} 为劫煞，主是非破败，需结合用神审慎判断。',
        ));
      }
    }
  }

  // 空亡（旬空）：每旬十干配十二支，余两支为空亡
  void _checkKongWang(
    List<ShenshaItem> results,
    BaziChart chart,
    String dayStem,
  ) {
    // 每旬十干配十二支，余两支为空亡。
    // 甲子旬空戌亥，甲戌旬空申酉，甲申旬空午未，
    // 甲午旬空辰巳，甲辰旬空寅卯，甲寅旬空子丑
    final dayStemIndex = BaziRuleEngine.stems.indexOf(dayStem);
    final dayBranchIndex = BaziRuleEngine.branches.indexOf(chart.day.branch);
    final xunStartStem = dayStemIndex - (dayStemIndex - dayBranchIndex) % 10;
    final xunGap1 = ((12 - (xunStartStem % 10)) + 10) % 12;
    final xunGap2 = (xunGap1 + 1) % 12;

    final kongWangBranches = {
      BaziRuleEngine.branches[xunGap1],
      BaziRuleEngine.branches[xunGap2],
    };

    for (final pillar in chart.pillars) {
      if (kongWangBranches.contains(pillar.branch)) {
        results.add(ShenshaItem(
          name: '空亡',
          target: '${pillar.label}支${pillar.branch}',
          description: '以日柱为基准，${pillar.branch} 落空亡，能量减半，吉凶需结合整体格局判断。',
        ));
      }
    }
  }
}
