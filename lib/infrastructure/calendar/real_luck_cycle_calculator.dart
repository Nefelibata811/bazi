// 自研大运推算，仅单测/算法基准；生产见 LunarLuckCycleCalculator。
import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/bazi_request.dart';
import '../../domain/entities/calendar_snapshot.dart';
import '../../domain/entities/flowing_year.dart';
import '../../domain/entities/luck_cycle.dart';
import '../../domain/entities/solar_term_info.dart';
import '../../domain/services/bazi_rule_engine.dart';
import '../../domain/services/luck_cycle_calculator.dart';
import '../../domain/value_objects/gender.dart';
import '../../domain/value_objects/yin_yang.dart';

class RealLuckCycleCalculator implements LuckCycleCalculator {
  const RealLuckCycleCalculator({
    required BaziRuleEngine ruleEngine,
  }) : _ruleEngine = ruleEngine;

  final BaziRuleEngine _ruleEngine;

  @override
  Future<List<LuckCycle>> calculate({
    required BaziRequest request,
    required CalendarSnapshot calendarSnapshot,
    required BaziChart chart,
    required List<SolarTermInfo> solarTerms,
  }) async {
    final birthMoment = calendarSnapshot.solarDateTime;
    final yearStem = chart.year.stem;
    final yearPolarity = _ruleEngine.stemPolarityOf(yearStem);
    final isMale = request.gender == Gender.male;

    // 大运顺逆排法：
    // 阳年男/阴年女 → 顺排（从月柱往后推）
    // 阳年女/阴年男 → 逆排（从月柱往前推）
    final forward = (yearPolarity == YinYang.yang && isMale) ||
        (yearPolarity == YinYang.yin && !isMale);

    final nearestTermIndex = _nearestTermIndex(birthMoment, solarTerms, forward);
    final nearestTerm = solarTerms[nearestTermIndex];
    final daysDiff = birthMoment.difference(nearestTerm.occurredAt).abs().inDays;
    final hoursDiff = birthMoment.difference(nearestTerm.occurredAt).abs().inHours % 24;

    // 起运岁数：3 天折合 1 岁，1 天折合 4 个月，1 个时辰折合 10 天
    final startAge = daysDiff / 3.0 + hoursDiff / (24 * 3);
    final startAgeYears = startAge.floor();
    final startAgeMonths = ((startAge - startAgeYears) * 12).round();
    final effectiveAge = startAgeYears + (startAgeMonths >= 6 ? 1 : 0);

    final startYear = birthMoment.year + effectiveAge;

    // 从月柱干支出发，按顺/逆方向依次生成十步大运的干支
    final monthStem = chart.month.stem;
    final monthBranch = chart.month.branch;
    final monthStemIndex = BaziRuleEngine.stems.indexOf(monthStem);
    final monthBranchIndex = BaziRuleEngine.branches.indexOf(monthBranch);

    return List<LuckCycle>.generate(10, (index) {
      final step = index + 1;
      final ganZhiIndex = forward
          ? (monthStemIndex + step, monthBranchIndex + step)
          : (monthStemIndex - step, monthBranchIndex - step);

      final stem = BaziRuleEngine.stems[_positiveMod(ganZhiIndex.$1, 10)];
      final branch = BaziRuleEngine.branches[_positiveMod(ganZhiIndex.$2, 12)];
      final ganZhi = '$stem$branch';
      final tenGod = _ruleEngine.tenGodFor(
        dayMasterStem: chart.dayMaster,
        targetStem: stem,
      );

      final cycleStartYear = startYear + (step - 1) * 10;
      final cycleEndYear = cycleStartYear + 9;
      final cycleStartAge = effectiveAge + (step - 1) * 10;
      final cycleEndAge = cycleStartAge + 9;

      return LuckCycle(
        index: step,
        ganZhi: ganZhi,
        tenGod: tenGod,
        startYear: cycleStartYear,
        endYear: cycleEndYear,
        startAge: cycleStartAge,
        endAge: cycleEndAge,
        flowingYears: _buildFlowingYears(
          cycleStartYear,
          cycleStartAge,
          stem,
          branch,
          chart.dayMaster,
        ),
      );
    });
  }

  List<FlowingYear> _buildFlowingYears(
    int startYear,
    int startAge,
    String luckStem,
    String luckBranch,
    String dayMaster,
  ) {
    return List<FlowingYear>.generate(10, (index) {
      final year = startYear + index;
      // 流年干支以实际公历年份为准，1984=甲子(60-甲子表序号0)
      const baseYear = 1984;
      final yearOffset = year - baseYear;
      final yearGanZhiIndex = _positiveMod(yearOffset, 60);
      final yearStem = BaziRuleEngine.stems[yearGanZhiIndex % 10];
      final yearBranch = BaziRuleEngine.branches[yearGanZhiIndex % 12];
      final yearGanZhi = '$yearStem$yearBranch';
      final yearTenGod = _ruleEngine.tenGodFor(
        dayMasterStem: dayMaster,
        targetStem: yearStem,
      );

      return FlowingYear(
        year: year,
        ganZhi: yearGanZhi,
        tenGod: yearTenGod,
      );
    });
  }

  // 顺排时取出生之后的最近节气，逆排时取出生之前的最近节气
  int _nearestTermIndex(
    DateTime birthMoment,
    List<SolarTermInfo> terms,
    bool forward,
  ) {
    if (forward) {
      for (var i = 0; i < terms.length; i++) {
        if (terms[i].occurredAt.isAfter(birthMoment)) {
          return i;
        }
      }
      return terms.length - 1;
    } else {
      for (var i = terms.length - 1; i >= 0; i--) {
        if (terms[i].occurredAt.isBefore(birthMoment)) {
          return i;
        }
      }
      return 0;
    }
  }

  int _positiveMod(int value, int mod) {
    return (value % mod + mod) % mod;
  }
}
