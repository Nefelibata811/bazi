import '../../domain/entities/calendar_snapshot.dart';
import '../../domain/entities/four_pillars.dart';
import '../../domain/entities/gan_zhi.dart';
import '../../domain/services/bazi_rule_engine.dart';
import '../../domain/services/four_pillars_calculator.dart';

class ApproxFourPillarsCalculator implements FourPillarsCalculator {
  const ApproxFourPillarsCalculator();

  static const List<_MonthBoundary> _monthBoundaries = [
    _MonthBoundary(month: 2, day: 4, branch: '寅', orderFromYin: 0),
    _MonthBoundary(month: 3, day: 6, branch: '卯', orderFromYin: 1),
    _MonthBoundary(month: 4, day: 5, branch: '辰', orderFromYin: 2),
    _MonthBoundary(month: 5, day: 6, branch: '巳', orderFromYin: 3),
    _MonthBoundary(month: 6, day: 6, branch: '午', orderFromYin: 4),
    _MonthBoundary(month: 7, day: 7, branch: '未', orderFromYin: 5),
    _MonthBoundary(month: 8, day: 8, branch: '申', orderFromYin: 6),
    _MonthBoundary(month: 9, day: 8, branch: '酉', orderFromYin: 7),
    _MonthBoundary(month: 10, day: 8, branch: '戌', orderFromYin: 8),
    _MonthBoundary(month: 11, day: 7, branch: '亥', orderFromYin: 9),
    _MonthBoundary(month: 12, day: 7, branch: '子', orderFromYin: 10),
    _MonthBoundary(month: 1, day: 6, branch: '丑', orderFromYin: 11),
  ];

  @override
  Future<FourPillars> calculate(CalendarSnapshot snapshot) async {
    final dateTime = snapshot.solarDateTime;
    final yearPillar = _yearPillar(dateTime);
    final monthPillar = _monthPillar(dateTime, yearPillar.stem);
    final dayPillar = _dayPillar(dateTime);
    final hourPillar = _hourPillar(dateTime, dayPillar.stem);

    return FourPillars(
      year: yearPillar,
      month: monthPillar,
      day: dayPillar,
      hour: hourPillar,
    );
  }

  GanZhi _yearPillar(DateTime dateTime) {
    // 年柱应以立春为界，这里先用常见近似值 2 月 4 日作为边界，
    // 后续接入精确节气时只需要替换这个边界判断。
    final startOfYear = DateTime(dateTime.year, 2, 4);
    final effectiveYear = dateTime.isBefore(startOfYear)
        ? dateTime.year - 1
        : dateTime.year;
    const baseYear = 1984; // 1984 为甲子年，适合作为 60 甲子循环参考点。
    final offset = _positiveMod(effectiveYear - baseYear, 60);

    return GanZhi(
      stem: BaziRuleEngine.stems[offset % 10],
      branch: BaziRuleEngine.branches[offset % 12],
    );
  }

  GanZhi _monthPillar(DateTime dateTime, String yearStem) {
    final boundary = _resolveMonthBoundary(dateTime);
    final firstMonthStem = _firstMonthStemForYearStem(yearStem);
    final firstMonthStemIndex = BaziRuleEngine.stems.indexOf(firstMonthStem);
    final stemIndex = (firstMonthStemIndex + boundary.orderFromYin) % 10;

    return GanZhi(
      stem: BaziRuleEngine.stems[stemIndex],
      branch: boundary.branch,
    );
  }

  GanZhi _dayPillar(DateTime dateTime) {
    // 日柱先采用常见的公历通用公式，便于快速形成可运行版本。
    // 后续若要追求更高精度，可替换为儒略日/历书基准的统一实现。
    var year = dateTime.year;
    var month = dateTime.month;
    final day = dateTime.day;

    if (month == 1 || month == 2) {
      year -= 1;
      month += 12;
    }

    final century = year ~/ 100;
    final yearInCentury = year % 100;
    final monthAdjust = month.isEven ? 6 : 0;

    final stemIndex = _positiveMod(
      4 * century +
          century ~/ 4 +
          5 * yearInCentury +
          yearInCentury ~/ 4 +
          3 * (month + 1) ~/ 5 +
          day -
          3,
      10,
    );

    final branchIndex = _positiveMod(
      8 * century +
          century ~/ 4 +
          5 * yearInCentury +
          yearInCentury ~/ 4 +
          3 * (month + 1) ~/ 5 +
          day +
          7 +
          monthAdjust,
      12,
    );

    return GanZhi(
      stem: BaziRuleEngine.stems[stemIndex],
      branch: BaziRuleEngine.branches[branchIndex],
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

  _MonthBoundary _resolveMonthBoundary(DateTime dateTime) {
    final currentCode = dateTime.month * 100 + dateTime.day;
    final descending = _monthBoundaries
        .where((item) => item.month != 1)
        .toList()
      ..sort((a, b) => (b.month * 100 + b.day).compareTo(a.month * 100 + a.day));

    for (final item in descending) {
      final boundaryCode = item.month * 100 + item.day;
      if (currentCode >= boundaryCode) {
        return item;
      }
    }

    if (currentCode >= 106) {
      return _monthBoundaries.last;
    }

    // 1 月 6 日前仍属于上一节令区间，对应子月。
    return _monthBoundaries[_monthBoundaries.length - 2];
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

class _MonthBoundary {
  const _MonthBoundary({
    required this.month,
    required this.day,
    required this.branch,
    required this.orderFromYin,
  });

  final int month;
  final int day;
  final String branch;
  final int orderFromYin;
}
