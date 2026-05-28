// 文件：四柱calculator
//
// 路径：`lib/domain/services/four_pillars_calculator.dart`。
//
import '../entities/calendar_snapshot.dart';
import '../entities/four_pillars.dart';

abstract class FourPillarsCalculator {
  Future<FourPillars> calculate(CalendarSnapshot snapshot);
}
