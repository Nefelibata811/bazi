// 用例：根据 BaziRequest 生成完整 BaziReport（历法 → 四柱 → 大运 → 格局/神煞/用神）。
// 排盘主流程入口，由 BaziInputController 调用。
import '../entities/bazi_report.dart';
import '../entities/bazi_request.dart';
import '../services/bazi_calculator.dart';
import '../services/calendar_converter.dart';
import '../services/luck_cycle_calculator.dart';
import '../services/ren_yuan_si_ling_calculator.dart';
import '../services/solar_term_provider.dart';
import '../value_objects/si_ling_version.dart';
import '../../infrastructure/calendar/lunar_bazi_calculator.dart';
import 'analyze_bazi_usecase.dart';
import 'build_bazi_chart_usecase.dart';

class BuildBaziReportUseCase {
  const BuildBaziReportUseCase({
    required CalendarConverter calendarConverter,
    required SolarTermProvider solarTermProvider,
    required LuckCycleCalculator luckCycleCalculator,
    required BuildBaziChartUseCase buildChartUseCase,
    required AnalyzeBaziUseCase analyzeBaziUseCase,
    required BaziCalculator baziCalculator,
    RenYuanSiLingCalculator? renYuanSiLingCalculator,
  })  : _calendarConverter = calendarConverter,
        _solarTermProvider = solarTermProvider,
        _luckCycleCalculator = luckCycleCalculator,
        _buildChartUseCase = buildChartUseCase,
        _analyzeBaziUseCase = analyzeBaziUseCase,
        _baziCalculator = baziCalculator,
        _renYuanSiLingCalculator = renYuanSiLingCalculator;

  final CalendarConverter _calendarConverter;
  final SolarTermProvider _solarTermProvider;
  final LuckCycleCalculator _luckCycleCalculator;
  final BuildBaziChartUseCase _buildChartUseCase;
  final AnalyzeBaziUseCase _analyzeBaziUseCase;
  final BaziCalculator _baziCalculator;
  final RenYuanSiLingCalculator? _renYuanSiLingCalculator;

  Future<BaziReport> call(BaziRequest request) async {
    final calendarSnapshot = await _calendarConverter.resolve(request);
    final solarTerms = await _solarTermProvider.surroundingTerms(
      calendarSnapshot.solarDateTime,
    );
    final chart = await _buildChartUseCase(request);
    final luckCycles = await _luckCycleCalculator.calculate(
      request: request,
      calendarSnapshot: calendarSnapshot,
      chart: chart,
      solarTerms: solarTerms,
    );
    final analysis = await _analyzeBaziUseCase(
      chart,
      gender: request.gender,
    );

    BoneWeight? boneWeight;
    if (_baziCalculator is LunarBaziCalculator) {
      boneWeight = (_baziCalculator).calculateBoneWeight(request);
    }

    final renYuanSiLing = await _renYuanSiLingCalculator?.calculate(
      solarDateTime: calendarSnapshot.solarDateTime,
      monthBranch: chart.month.branch,
      version: SiLingVersion.common,
    );

    return BaziReport(
      request: request,
      calendarSnapshot: calendarSnapshot,
      chart: chart,
      solarTerms: solarTerms,
      luckCycles: luckCycles,
      analysis: analysis,
      boneWeight: boneWeight,
      renYuanSiLing: renYuanSiLing,
    );
  }
}
