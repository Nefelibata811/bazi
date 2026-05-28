// 文件：规则格局analyzer
//
// 历法算法：八字排盘核心计算。
// 路径：`lib/infrastructure/calendar/rule_pattern_analyzer.dart`。
//
import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/pattern_result.dart';
import '../../domain/services/bazi_rule_engine.dart';
import '../../domain/services/pattern_analyzer.dart';
import '../../domain/value_objects/five_element.dart';

/// 类 `RulePatternAnalyzer`：实现 Rule Pattern Analyzer 相关逻辑。
class RulePatternAnalyzer implements PatternAnalyzer {
  const RulePatternAnalyzer({
    required BaziRuleEngine ruleEngine,
  }) : _ruleEngine = ruleEngine;

  final BaziRuleEngine _ruleEngine;

  // 月支到格局名映射：以月令地支对应的本气藏干为格神起点
  static const _branchToPatternStem = {
    '寅': '甲',
    '卯': '乙',
    '辰': '戊',
    '巳': '丙',
    '午': '丁',
    '未': '己',
    '申': '庚',
    '酉': '辛',
    '戌': '戊',
    '亥': '壬',
    '子': '癸',
    '丑': '己',
  };

  // 十神到格局名映射
  static const _tenGodToPattern = {
    '正官': '正官格',
    '七杀': '七杀格',
    '正财': '正财格',
    '偏财': '偏财格',
    '正印': '正印格',
    '偏印': '偏印格',
    '食神': '食神格',
    '伤官': '伤官格',
    '比肩': '建禄格',
    '劫财': '月刃格',
  };

  @override
  Future<List<PatternResult>> analyze(BaziChart chart) async {
    final results = <PatternResult>[];
    final dayMaster = chart.dayMaster;
    final monthBranch = chart.month.branch;

    // 第一步：按月令本气定格神
    final patternStem = _branchToPatternStem[monthBranch];
    if (patternStem == null) {
      return [
        PatternResult(
          name: '未定格',
          summary: '月支 $monthBranch 未能识别对应格神。',
          evidence: ['月支不在常规映射中'],
          confidence: 0,
        ),
      ];
    }

    final godRelation = _ruleEngine.tenGodFor(
      dayMasterStem: dayMaster,
      targetStem: patternStem,
    );

    final basePattern = _tenGodToPattern[godRelation] ?? '$godRelation格';

    // 第二步：检查是否透干 —— 月干、年干、时干是否透出格神
    final exposedInMonth = chart.month.stem == patternStem;
    final exposedInYear = chart.year.stem == patternStem;
    final exposedInHour = chart.hour.stem == patternStem;
    final exposed = exposedInMonth || exposedInYear || exposedInHour;

    // 第三步：检查是否有官杀混杂或财印交加
    final hasMixed = _hasMixedGod(chart);

    final evidence = <String>[];
    if (exposedInMonth) {
      evidence.add('月干透出格神 $patternStem，格局清纯。');
    } else if (exposedInYear) {
      evidence.add('年干透出格神 $patternStem，格神远透。');
    } else if (exposedInHour) {
      evidence.add('时干透出格神 $patternStem，格神通根。');
    } else {
      evidence.add('格神 $patternStem 藏于月支而未透干，取格稍弱。');
    }

    if (hasMixed) {
      evidence.add('四柱中有官杀混杂或财印交加，格局层次需具体分辨。');
    }

    // 第四步：计算置信度
    double confidence = 0.5;
    if (exposedInMonth) confidence += 0.25;
    if (exposedInYear) confidence += 0.10;
    if (exposedInHour) confidence += 0.10;
    if (!hasMixed) confidence += 0.05;
    confidence = confidence.clamp(0.2, 0.95);

    final summary = _buildSummary(
      basePattern,
      exposed,
      hasMixed,
      dayMaster,
      patternStem,
    );

    results.add(PatternResult(
      name: basePattern,
      summary: summary,
      evidence: evidence,
      confidence: confidence,
    ));

    // 第五步：兼格检查 —— 若月干透出且非格神，可能有兼格
    if (chart.month.stem != patternStem && chart.month.stem != dayMaster) {
      final secondaryGod = _ruleEngine.tenGodFor(
        dayMasterStem: dayMaster,
        targetStem: chart.month.stem,
      );
      final secondaryPattern = _tenGodToPattern[secondaryGod];

      if (secondaryPattern != null &&
          secondaryPattern != basePattern &&
          secondaryGod != '比肩' &&
          secondaryGod != '劫财') {
        results.add(PatternResult(
          name: '兼$secondaryPattern',
          summary: '月干透出 ${chart.month.stem} 为 $secondaryGod，可视为兼格参考。',
          evidence: ['月干非格神但透干，构成兼格参考维度。'],
          confidence: 0.35,
        ));
      }
    }

    return results;
  }

  String _buildSummary(
    String basePattern,
    bool exposed,
    bool hasMixed,
    String dayMaster,
    String patternStem,
  ) {
    final dayElement = _ruleEngine.stemElementOf(dayMaster);
    final patternElement = _ruleEngine.stemElementOf(patternStem);

    final expo = exposed ? '格神透干，层次较高' : '格神未透干，层次稍降';
    final mixed = hasMixed ? '，但存官杀/财印混杂，需细辨扶抑喜忌。' : '。';

    final strength = _describeElementRelation(dayElement, patternElement);

    return '以月令 $patternStem 立 $basePattern，$expo$mixed$strength';
  }

  String _describeElementRelation(FiveElement day, FiveElement pattern) {
    if (day == pattern) return '';
    final ctrl = [
      (FiveElement.wood, FiveElement.earth),
      (FiveElement.fire, FiveElement.metal),
      (FiveElement.earth, FiveElement.water),
      (FiveElement.metal, FiveElement.wood),
      (FiveElement.water, FiveElement.fire),
    ];

    for (final (controller, controlled) in ctrl) {
      if (day == controller && pattern == controlled) return '（日主克格神）';
      if (day == controlled && pattern == controller) return '（格神克日主）';
    }
    return '';
  }

  // 简易官杀混杂或财印交加检测
  bool _hasMixedGod(BaziChart chart) {
    int zhengGuan = 0, qiSha = 0, zhengCai = 0, pianCai = 0, zhengYin = 0, pianYin = 0;

    for (final pillar in chart.pillars) {
      final god = pillar.isDayColumn
          ? null
          : _ruleEngine.tenGodFor(
              dayMasterStem: chart.dayMaster,
              targetStem: pillar.stem,
            );

      switch (god) {
        case '正官':
          zhengGuan++;
          break;
        case '七杀':
          qiSha++;
          break;
        case '正财':
          zhengCai++;
          break;
        case '偏财':
          pianCai++;
          break;
        case '正印':
          zhengYin++;
          break;
        case '偏印':
          pianYin++;
          break;
      }
    }

    return (zhengGuan > 0 && qiSha > 0) ||
        (zhengCai > 0 && pianCai > 0) ||
        (zhengYin > 0 && pianYin > 0);
  }
}
