import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/shensha_item.dart';
import '../../domain/services/shensha_calculator.dart';

class RuleShenshaCalculator implements ShenshaCalculator {
  const RuleShenshaCalculator();

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

  static const _yiMa = {
    '申': '寅', '子': '寅', '辰': '寅',
    '寅': '申', '午': '申', '戌': '申',
    '巳': '亥', '酉': '亥', '丑': '亥',
    '亥': '巳', '卯': '巳', '未': '巳',
  };

  static const _taoHua = {
    '申': '酉', '子': '酉', '辰': '酉',
    '寅': '卯', '午': '卯', '戌': '卯',
    '巳': '午', '酉': '午', '丑': '午',
    '亥': '子', '卯': '子', '未': '子',
  };

  static const _huaGai = {
    '申': '辰', '子': '辰', '辰': '辰',
    '寅': '戌', '午': '戌', '戌': '戌',
    '巳': '丑', '酉': '丑', '丑': '丑',
    '亥': '未', '卯': '未', '未': '未',
  };

  static const _wangShen = {
    '申': '亥', '子': '亥', '辰': '亥',
    '寅': '巳', '午': '巳', '戌': '巳',
    '巳': '申', '酉': '申', '丑': '申',
    '亥': '寅', '卯': '寅', '未': '寅',
  };

  static const _jieSha = {
    '申': '巳', '子': '巳', '辰': '巳',
    '寅': '亥', '午': '亥', '戌': '亥',
    '巳': '寅', '酉': '寅', '丑': '寅',
    '亥': '申', '卯': '申', '未': '申',
  };

  static const _jiangXing = {
    '申': '子', '子': '子', '辰': '子',
    '寅': '午', '午': '午', '戌': '午',
    '巳': '酉', '酉': '酉', '丑': '酉',
    '亥': '卯', '卯': '卯', '未': '卯',
  };

  static const _zaiSha = {
    '申': '午', '子': '午', '辰': '午',
    '寅': '子', '午': '子', '戌': '子',
    '巳': '卯', '酉': '卯', '丑': '卯',
    '亥': '酉', '卯': '酉', '未': '酉',
  };

  static const _wenChang = {
    '甲': '巳', '乙': '午', '丙': '申', '丁': '酉',
    '戊': '申', '己': '酉', '庚': '亥', '辛': '子',
    '壬': '寅', '癸': '卯',
  };

  static const _luShen = {
    '甲': '寅', '乙': '卯', '丙': '巳', '丁': '午',
    '戊': '巳', '己': '午', '庚': '申', '辛': '酉',
    '壬': '亥', '癸': '子',
  };

  static const _yangRen = {
    '甲': '卯', '乙': '寅', '丙': '午', '丁': '巳',
    '戊': '午', '己': '巳', '庚': '酉', '辛': '申',
    '壬': '子', '癸': '亥',
  };

  static const _jinYu = {
    '甲': '辰', '乙': '巳', '丙': '未', '丁': '申',
    '戊': '未', '己': '申', '庚': '戌', '辛': '亥',
    '壬': '丑', '癸': '寅',
  };

  static const _hongLuan = {
    '子': '卯', '丑': '寅', '寅': '丑', '卯': '子',
    '辰': '亥', '巳': '戌', '午': '酉', '未': '申',
    '申': '未', '酉': '午', '戌': '巳', '亥': '辰',
  };

  static const _tianXi = {
    '子': '酉', '丑': '申', '寅': '未', '卯': '午',
    '辰': '巳', '巳': '辰', '午': '卯', '未': '寅',
    '申': '丑', '酉': '子', '戌': '亥', '亥': '戌',
  };

  static const _guChen = {
    '亥': '寅', '子': '寅', '丑': '寅',
    '寅': '巳', '卯': '巳', '辰': '巳',
    '巳': '申', '午': '申', '未': '申',
    '申': '亥', '酉': '亥', '戌': '亥',
  };

  static const _guaSu = {
    '亥': '戌', '子': '戌', '丑': '戌',
    '寅': '丑', '卯': '丑', '辰': '丑',
    '巳': '辰', '午': '辰', '未': '辰',
    '申': '未', '酉': '未', '戌': '未',
  };

  static const _kuiGangDays = {'庚辰', '庚戌', '壬辰', '戊戌'};

  @override
  Future<List<ShenshaItem>> calculate(BaziChart chart) async {
    final results = <ShenshaItem>[];
    final dayStem = chart.dayMaster;
    final yearBranch = chart.year.branch;
    final dayBranch = chart.day.branch;
    final dayGanZhi = '${chart.day.stem}${chart.day.branch}';

    _checkTianYi(results, chart, dayStem);
    _checkStemBased(results, chart, dayStem, '日干');
    _checkBranchBased(results, chart, yearBranch, '年支');
    _checkBranchBased(results, chart, dayBranch, '日支');
    _checkYearBranchSingle(results, chart, yearBranch);
    _checkKuiGang(results, chart, dayGanZhi);

    return results;
  }

  void _add(
    List<ShenshaItem> results,
    ShenshaItem item,
  ) {
    final key = '${item.name}|${item.target}';
    if (results.any((e) => '${e.name}|${e.target}' == key)) return;
    results.add(item);
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
        _add(
          results,
          ShenshaItem(
            name: '天乙贵人',
            target: '${pillar.label}支${pillar.branch}',
            description: '日干 $dayStem 见 ${pillar.branch} 为天乙贵人，主逢凶化吉、贵人相助。',
          ),
        );
      }
    }
  }

  void _checkStemBased(
    List<ShenshaItem> results,
    BaziChart chart,
    String dayStem,
    String baseLabel,
  ) {
    final checks = <String, Map<String, String>>{
      '文昌': _wenChang,
      '禄神': _luShen,
      '羊刃': _yangRen,
      '金舆': _jinYu,
    };

    final descriptions = {
      '文昌': '$baseLabel $dayStem 见 %s 为文昌，主聪慧好学、利于考试与文书。',
      '禄神': '$baseLabel $dayStem 见 %s 为禄神（临官），主福禄、自立与事业根基。',
      '羊刃': '$baseLabel $dayStem 见 %s 为羊刃，主刚强果断，过旺则宜制化。',
      '金舆': '$baseLabel $dayStem 见 %s 为金舆，主车马衣食、出行顺遂之象。',
    };

    for (final entry in checks.entries) {
      final targetBranch = entry.value[dayStem];
      if (targetBranch == null) continue;
      for (final pillar in chart.pillars) {
        if (pillar.branch == targetBranch) {
          _add(
            results,
            ShenshaItem(
              name: entry.key,
              target: '${pillar.label}支${pillar.branch}',
              description: descriptions[entry.key]!
                  .replaceFirst('%s', pillar.branch),
            ),
          );
        }
      }
    }
  }

  void _checkBranchBased(
    List<ShenshaItem> results,
    BaziChart chart,
    String baseBranch,
    String baseLabel,
  ) {
    final rules = <String, Map<String, String>>{
      '驿马': _yiMa,
      '桃花': _taoHua,
      '华盖': _huaGai,
      '亡神': _wangShen,
      '劫煞': _jieSha,
      '将星': _jiangXing,
      '灾煞': _zaiSha,
    };

    final descriptions = {
      '驿马': '$baseLabel $baseBranch 见 %s 为驿马，主动荡、迁移、奔波。',
      '桃花': '$baseLabel $baseBranch 见 %s 为桃花（咸池），主人缘情感，须结合十神。',
      '华盖': '$baseLabel $baseBranch 见 %s 为华盖，主学术、艺术、玄学气质。',
      '亡神': '$baseLabel $baseBranch 见 %s 为亡神，主官非口舌，亦为魄力。',
      '劫煞': '$baseLabel $baseBranch 见 %s 为劫煞，主是非破败，宜结合用神。',
      '将星': '$baseLabel $baseBranch 见 %s 为将星，主权威、统御与决断力。',
      '灾煞': '$baseLabel $baseBranch 见 %s 为灾煞，主意外波折，宜慎行。',
    };

    for (final entry in rules.entries) {
      final targetBranch = entry.value[baseBranch];
      if (targetBranch == null) continue;
      for (final pillar in chart.pillars) {
        if (pillar.branch == targetBranch) {
          _add(
            results,
            ShenshaItem(
              name: entry.key,
              target: '${pillar.label}支${pillar.branch}',
              description: descriptions[entry.key]!
                  .replaceFirst('%s', pillar.branch),
            ),
          );
        }
      }
    }
  }

  void _checkYearBranchSingle(
    List<ShenshaItem> results,
    BaziChart chart,
    String yearBranch,
  ) {
    final hongLuan = _hongLuan[yearBranch];
    final tianXi = _tianXi[yearBranch];
    final guChen = _guChen[yearBranch];
    final guaSu = _guaSu[yearBranch];

    for (final pillar in chart.pillars) {
      if (hongLuan != null && pillar.branch == hongLuan) {
        _add(
          results,
          ShenshaItem(
            name: '红鸾',
            target: '${pillar.label}支${pillar.branch}',
            description: '年支 $yearBranch 见 ${pillar.branch} 为红鸾，主婚恋喜庆、人缘和合。',
          ),
        );
      }
      if (tianXi != null && pillar.branch == tianXi) {
        _add(
          results,
          ShenshaItem(
            name: '天喜',
            target: '${pillar.label}支${pillar.branch}',
            description: '年支 $yearBranch 见 ${pillar.branch} 为天喜，主喜庆、好事将近。',
          ),
        );
      }
      if (guChen != null && pillar.branch == guChen) {
        _add(
          results,
          ShenshaItem(
            name: '孤辰',
            target: '${pillar.label}支${pillar.branch}',
            description: '年支 $yearBranch 见 ${pillar.branch} 为孤辰，主性格孤高，宜修身养性。',
          ),
        );
      }
      if (guaSu != null && pillar.branch == guaSu) {
        _add(
          results,
          ShenshaItem(
            name: '寡宿',
            target: '${pillar.label}支${pillar.branch}',
            description: '年支 $yearBranch 见 ${pillar.branch} 为寡宿，主寡静少合，感情宜审慎。',
          ),
        );
      }
    }
  }

  void _checkKuiGang(
    List<ShenshaItem> results,
    BaziChart chart,
    String dayGanZhi,
  ) {
    if (!_kuiGangDays.contains(dayGanZhi)) return;
    _add(
      results,
      ShenshaItem(
        name: '魁罡',
        target: '日柱$dayGanZhi',
        description: '日柱 $dayGanZhi 为魁罡，性格刚毅果决，有威权领导之象，忌刑冲过甚。',
      ),
    );
  }
}
