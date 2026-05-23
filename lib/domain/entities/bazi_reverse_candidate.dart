import '../value_objects/bazi_sect.dart';
import '../value_objects/gender.dart';

/// 反查命中的公历时刻候选。
class BaziReverseCandidate {
  const BaziReverseCandidate({
    required this.solarDateTime,
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.timeGanZhi,
    this.isLateZi = false,
    this.gender = Gender.male,
    this.baziSect = BaziSect.sameDay,
  });

  final DateTime solarDateTime;
  final String yearGanZhi;
  final String monthGanZhi;
  final String dayGanZhi;
  final String timeGanZhi;
  final bool isLateZi;
  final Gender gender;
  final BaziSect baziSect;

  String get ganZhiLine => '$yearGanZhi $monthGanZhi $dayGanZhi $timeGanZhi';

  String get dateLabel {
    final dt = solarDateTime;
    final zi = isLateZi ? '（晚子时）' : '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}$zi';
  }
}
