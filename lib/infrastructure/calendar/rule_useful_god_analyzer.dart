import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/pattern_result.dart';
import '../../domain/entities/useful_god_result.dart';
import '../../domain/services/bazi_rule_engine.dart';
import '../../domain/services/useful_god_analyzer.dart';
import '../../domain/value_objects/five_element.dart';

class RuleUsefulGodAnalyzer implements UsefulGodAnalyzer {
  const RuleUsefulGodAnalyzer({
    required BaziRuleEngine ruleEngine,
  }) : _ruleEngine = ruleEngine;

  final BaziRuleEngine _ruleEngine;

  static const _monthPrimaryElement = {
    '寅': FiveElement.wood,
    '卯': FiveElement.wood,
    '辰': FiveElement.earth,
    '巳': FiveElement.fire,
    '午': FiveElement.fire,
    '未': FiveElement.earth,
    '申': FiveElement.metal,
    '酉': FiveElement.metal,
    '戌': FiveElement.earth,
    '亥': FiveElement.water,
    '子': FiveElement.water,
    '丑': FiveElement.earth,
  };

  // 四季土月余气：辰为水库、未为木库、戌为火库、丑为金库
  // 用于月令扶抑判断时辅助参考，本库余气可为日主提供根气
  static const _reservoirElement = {
    '辰': FiveElement.water,
    '未': FiveElement.wood,
    '戌': FiveElement.fire,
    '丑': FiveElement.metal,
  };

  static const _generates = {
    FiveElement.wood: FiveElement.fire,
    FiveElement.fire: FiveElement.earth,
    FiveElement.earth: FiveElement.metal,
    FiveElement.metal: FiveElement.water,
    FiveElement.water: FiveElement.wood,
  };

  static const _controls = {
    FiveElement.wood: FiveElement.earth,
    FiveElement.fire: FiveElement.metal,
    FiveElement.earth: FiveElement.water,
    FiveElement.metal: FiveElement.wood,
    FiveElement.water: FiveElement.fire,
  };

  @override
  Future<UsefulGodResult> analyze({
    required BaziChart chart,
    required List<PatternResult> patterns,
  }) async {
    final dayElement = _ruleEngine.stemElementOf(chart.dayMaster);
    final monthBranch = chart.month.branch;
    final monthElement = _monthPrimaryElement[monthBranch] ?? FiveElement.earth;
    final reservoirElement = _reservoirElement[monthBranch];

    double score = _monthScore(dayElement, monthElement, reservoirElement);

    for (final pillar in chart.pillars) {
      if (pillar.label == '日柱') continue;

      final stemGod = _ruleEngine.tenGodFor(
        dayMasterStem: chart.dayMaster,
        targetStem: pillar.stem,
      );
      if (stemGod == '比肩' || stemGod == '劫财') score += 1.0;
      if (stemGod == '正印' || stemGod == '偏印') score += 1.0;
      if (stemGod == '正官' || stemGod == '七杀') score -= 1.0;

      for (final hidden in pillar.hiddenStems) {
        final hiddenGod = _ruleEngine.tenGodFor(
          dayMasterStem: chart.dayMaster,
          targetStem: hidden.stem,
        );
        if (hiddenGod == '比肩' || hiddenGod == '劫财') score += 0.5;
        if (hiddenGod == '正印' || hiddenGod == '偏印') score += 0.5;
      }
    }

    final intScore = score.round();

    String strength;
    if (intScore >= 5) {
      strength = '日主偏强';
    } else if (intScore >= 2) {
      strength = '日主中和偏旺';
    } else if (intScore >= -1) {
      strength = '日主中和';
    } else if (intScore >= -3) {
      strength = '日主中和偏弱';
    } else {
      strength = '日主偏弱';
    }

    final patternName = patterns.isNotEmpty ? patterns.first.name : null;
    final String usefulGod;
    final String supportiveGod;
    final String avoidGod;

    if (intScore >= 2) {
      usefulGod = _describeControllingElements(dayElement);
      supportiveGod = '食财官';
      avoidGod = '印比';
    } else if (intScore <= -3) {
      usefulGod = _describeSupportingElements(dayElement);
      supportiveGod = '印比';
      avoidGod = '官财食';
    } else {
      usefulGod = _describeBalanceElements(dayElement, patternName);
      supportiveGod = '按格局调候';
      avoidGod = '忌过强过弱';
    }

    final summary = StringBuffer()
      ..write('当前 ${patternName ?? '格局未定'}，$strength（评分 $intScore）。')
      ..write('宜取 $usefulGod 为用，$supportiveGod 为喜，忌 $avoidGod。')
      ..write('以上供参考，详细请结合岁运综合判断。');

    return UsefulGodResult(
      dayMasterStrength: strength,
      usefulGod: usefulGod,
      supportiveGod: supportiveGod,
      avoidGod: avoidGod,
      summary: summary.toString(),
    );
  }

  double _monthScore(
    FiveElement dayElement,
    FiveElement monthElement,
    FiveElement? reservoirElement,
  ) {
    double score = 0;

    if (dayElement == monthElement) {
      score += 3.0;
    } else if (_generates[monthElement] == dayElement) {
      score += 2.0;
    } else if (_controls[dayElement] == monthElement) {
      score += 1.0;
    } else if (_generates[dayElement] == monthElement) {
      score -= 1.0;
    } else if (_controls[monthElement] == dayElement) {
      score -= 3.0;
    }

    if (reservoirElement != null && dayElement == reservoirElement) {
      score += 0.5;
    }

    return score;
  }

  String _describeControllingElements(FiveElement day) {
    switch (day) {
      case FiveElement.wood:
        return '火土金';
      case FiveElement.fire:
        return '土金水';
      case FiveElement.earth:
        return '金水木';
      case FiveElement.metal:
        return '水木火';
      case FiveElement.water:
        return '木火土';
    }
  }

  String _describeSupportingElements(FiveElement day) {
    switch (day) {
      case FiveElement.wood:
        return '水木';
      case FiveElement.fire:
        return '木火';
      case FiveElement.earth:
        return '火土';
      case FiveElement.metal:
        return '土金';
      case FiveElement.water:
        return '金水';
    }
  }

  String _describeBalanceElements(FiveElement day, String? patternName) {
    if (patternName != null && patternName.contains('官')) return '印比';
    if (patternName != null && patternName.contains('财')) return '食伤';
    if (patternName != null && patternName.contains('印')) return '财';
    return '按格局调候';
  }
}
