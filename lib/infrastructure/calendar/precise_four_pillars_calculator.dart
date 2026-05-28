// 文件：precise四柱calculator
//
// 历法算法：八字排盘核心计算。
// 路径：`lib/infrastructure/calendar/precise_four_pillars_calculator.dart`。
//
// 自研四柱推算，仅单测/算法基准；生产排盘见 LunarBaziCalculator。
import '../../domain/entities/calendar_snapshot.dart';
import '../../domain/entities/four_pillars.dart';
import '../../domain/entities/gan_zhi.dart';
import '../../domain/entities/solar_term_info.dart';
import '../../domain/services/bazi_rule_engine.dart';
import '../../domain/services/four_pillars_calculator.dart';
import '../../domain/services/julian_day.dart';
import '../../domain/services/solar_term_provider.dart';

/// 类 `PreciseFourPillarsCalculator`：实现 Precise Four Pillars Calculator 相关逻辑。
class PreciseFourPillarsCalculator implements FourPillarsCalculator {
  PreciseFourPillarsCalculator({
    required SolarTermProvider solarTermProvider,
  }) : _solarTermProvider = solarTermProvider;

  final SolarTermProvider _solarTermProvider;

  @override
  Future<FourPillars> calculate(CalendarSnapshot snapshot) async {
    final dateTime = snapshot.solarDateTime;
    final solarTerms = await _solarTermProvider.termsOfYear(dateTime.year);

    final yearPillar = _yearPillarByTerm(dateTime, solarTerms);
    final monthPillar = _monthPillarByTerm(dateTime, yearPillar.stem, solarTerms);
    final dayPillar = _dayPillar(dateTime);
    final hourPillar = _hourPillar(dateTime, dayPillar.stem);

    return FourPillars(
      year: yearPillar,
      month: monthPillar,
      day: dayPillar,
      hour: hourPillar,
    );
  }

  GanZhi _yearPillarByTerm(DateTime dateTime, List<SolarTermInfo> terms) {
    // 以精确立春时刻（节气表 index=2）为界切年。
    // 出生在立春之前归入上一年干支。
    final liChun = terms.cast<SolarTermInfo?>().firstWhere(
      (t) => t?.index == 2,
      orElse: () => null,
    );
    final effectiveYear = liChun != null && dateTime.isBefore(liChun.occurredAt)
        ? dateTime.year - 1
        : dateTime.year;

    const baseYear = 1984;
    final offset = _positiveMod(effectiveYear - baseYear, 60);

    return GanZhi(
      stem: BaziRuleEngine.stems[offset % 10],
      branch: BaziRuleEngine.branches[offset % 12],
    );
  }

  GanZhi _monthPillarByTerm(
    DateTime dateTime,
    String yearStem,
    List<SolarTermInfo> terms,
  ) {
    // 月柱以节气表"节"项为界。
    // 节气表 index 为偶数者为"节"（0=小寒, 2=立春, 4=惊蛰, ...）。
    // 取 dateTime 所在区间内的最近一个"节"确定月支。
    final jiTerms = terms
        .where((t) => t.index.isEven && t.termMonth != null)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    int? termMonth;
    for (final t in jiTerms) {
      if (!dateTime.isBefore(t.occurredAt)) {
        termMonth = t.termMonth;
        break;
      }
    }
    // 如果出生在全年第一个"节"之前，则属于上一年的最后一个月。
    termMonth ??= 11;

    final firstMonthStem = _firstMonthStemForYearStem(yearStem);
    final firstMonthStemIndex = BaziRuleEngine.stems.indexOf(firstMonthStem);
    final stemIndex = (firstMonthStemIndex + termMonth) % 10;

    return GanZhi(
      stem: BaziRuleEngine.stems[stemIndex],
      branch: BaziRuleEngine.branches[(termMonth + 2) % 12],
    );
  }

  GanZhi _dayPillar(DateTime dateTime) {
    // 日柱以儒略日为基准，1900-01-01 = 甲戌日（干支序号 10）。
    // stemIndex = (第 10 个干支的天干序号 + 天数偏移) % 10
    // branchIndex = (第 10 个干支的地支序号 + 天数偏移) % 12
    final jd = JulianDay.fromDateTime(dateTime);
    // 1900-01-01 的儒略日（整数日界）≈ 2415021
    // 1900-01-01 干支 = 甲戌，在 60-甲子表中的序号 = 10
    const baseJd = 2415021;
    const baseGanZhiIndex = 10;

    final daysDiff = jd - baseJd;
    final ganzhiIndex = _positiveMod(baseGanZhiIndex + daysDiff, 60);

    return GanZhi(
      stem: BaziRuleEngine.stems[ganzhiIndex % 10],
      branch: BaziRuleEngine.branches[ganzhiIndex % 12],
    );
  }

  GanZhi _hourPillar(DateTime dateTime, String dayStem) {
    final branchIndex = ((dateTime.hour + 1) ~/ 2) % 12;
    final branch = BaziRuleEngine.branches[branchIndex];
    final firstHourStem = _firstHourStemForDayStem(dayStem);
    final firstHourStemIndex = BaziRuleEngine.stems.indexOf(firstHourStem);
    final stem = BaziRuleEngine.stems[(firstHourStemIndex + branchIndex) % 10];

    return GanZhi(
      stem: stem,
      branch: branch,
    );
  }

  String _firstMonthStemForYearStem(String yearStem) {
    switch (yearStem) {
      case '甲':
      case '己':
        return '丙';
      case '乙':
      case '庚':
        return '戊';
      case '丙':
      case '辛':
        return '庚';
      case '丁':
      case '壬':
        return '壬';
      case '戊':
      case '癸':
        return '甲';
      default:
        return '丙';
    }
  }

  String _firstHourStemForDayStem(String dayStem) {
    switch (dayStem) {
      case '甲':
      case '己':
        return '甲';
      case '乙':
      case '庚':
        return '丙';
      case '丙':
      case '辛':
        return '戊';
      case '丁':
      case '壬':
        return '庚';
      case '戊':
      case '癸':
        return '壬';
      default:
        return '甲';
    }
  }

  int _positiveMod(int value, int mod) {
    return (value % mod + mod) % mod;
  }
}
