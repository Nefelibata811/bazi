import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/bazi_request.dart';
import '../../domain/services/bazi_calculator.dart';
import '../../domain/services/bazi_rule_engine.dart';
import '../../domain/services/calendar_converter.dart';
import '../../domain/services/four_pillars_calculator.dart';
import '../../domain/services/solar_term_provider.dart';

class StubBaziCalculator implements BaziCalculator {
  const StubBaziCalculator({
    required BaziRuleEngine ruleEngine,
    required CalendarConverter calendarConverter,
    required FourPillarsCalculator fourPillarsCalculator,
    required SolarTermProvider solarTermProvider,
  })  : _ruleEngine = ruleEngine,
        _calendarConverter = calendarConverter,
        _fourPillarsCalculator = fourPillarsCalculator,
        _solarTermProvider = solarTermProvider;

  final BaziRuleEngine _ruleEngine;
  final CalendarConverter _calendarConverter;
  final FourPillarsCalculator _fourPillarsCalculator;
  final SolarTermProvider _solarTermProvider;

  @override
  Future<BaziChart> calculate(BaziRequest request) async {
    final calendar = await _calendarConverter.resolve(request);
    final solarTerms = await _solarTermProvider.surroundingTerms(
      calendar.solarDateTime,
    );
    final seasonalHint = solarTerms.isEmpty ? '平' : '令';
    final fourPillars = await _fourPillarsCalculator.calculate(calendar);
    final dayMaster = fourPillars.day.stem;

    // 四柱计算器负责产出年月日时干支，规则引擎负责把干支翻译成十神、
    // 藏干、纳音、长生等命理信息，两层解耦后便于后续分别升级算法。
    return BaziChart(
      dayMaster: dayMaster,
      year: _ruleEngine.buildPillar(
        label: '年柱',
        stem: fourPillars.year.stem,
        branch: fourPillars.year.branch,
        dayMasterStem: dayMaster,
      ),
      month: _ruleEngine.buildPillar(
        label: '月柱',
        stem: fourPillars.month.stem,
        branch: fourPillars.month.branch,
        dayMasterStem: dayMaster,
        growthPhaseSuffix: seasonalHint,
      ),
      day: _ruleEngine.buildPillar(
        label: '日柱',
        stem: fourPillars.day.stem,
        branch: fourPillars.day.branch,
        dayMasterStem: dayMaster,
      ),
      hour: _ruleEngine.buildPillar(
        label: '时柱',
        stem: fourPillars.hour.stem,
        branch: fourPillars.hour.branch,
        dayMasterStem: dayMaster,
      ),
    );
  }
}
