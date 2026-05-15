import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/bazi_request.dart';
import '../../domain/entities/calendar_snapshot.dart';
import '../../domain/entities/flowing_year.dart';
import '../../domain/entities/luck_cycle.dart';
import '../../domain/entities/solar_term_info.dart';
import '../../domain/services/luck_cycle_calculator.dart';
import '../../domain/value_objects/gender.dart';

class StubLuckCycleCalculator implements LuckCycleCalculator {
  @override
  Future<List<LuckCycle>> calculate({
    required BaziRequest request,
    required CalendarSnapshot calendarSnapshot,
    required BaziChart chart,
    required List<SolarTermInfo> solarTerms,
  }) async {
    // 这里先保留“顺逆与节气差影响起运点”的结构，
    // 后续可替换为出生时刻到最近节令的精确时差推算。
    final directionOffset = request.gender == Gender.male ? 6 : 7;
    final termOffset = solarTerms.isEmpty ? 0 : 1;
    final startYear = calendarSnapshot.solarDateTime.year + directionOffset;
    const cycles = [
      ['丁卯', '正财'],
      ['戊辰', '正官'],
      ['己巳', '七杀'],
      ['庚午', '正印'],
      ['辛未', '偏印'],
      ['壬申', '劫财'],
      ['癸酉', '比肩'],
      ['甲戌', '伤官'],
      ['乙亥', '食神'],
      ['丙子', '偏财'],
    ];

    return List<LuckCycle>.generate(cycles.length, (index) {
      final cycleStartYear = startYear + index * 10;
      final cycleEndYear = cycleStartYear + 9;
      final cycleStartAge = directionOffset + termOffset + index * 10;
      final cycleEndAge = cycleStartAge + 9;
      final ganZhi = cycles[index][0];
      final tenGod = cycles[index][1];
      final flowingYearTenGod = '$tenGod/${chart.dayMaster}';

      return LuckCycle(
        index: index + 1,
        ganZhi: ganZhi,
        tenGod: tenGod,
        startYear: cycleStartYear,
        endYear: cycleEndYear,
        startAge: cycleStartAge,
        endAge: cycleEndAge,
        flowingYears: List<FlowingYear>.generate(10, (yearIndex) {
          return FlowingYear(
            year: cycleStartYear + yearIndex,
            ganZhi: '$ganZhi-$yearIndex',
            tenGod: flowingYearTenGod,
          );
        }),
      );
    });
  }
}
