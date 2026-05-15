import '../entities/calendar_snapshot.dart';
import '../entities/four_pillars.dart';

abstract class FourPillarsCalculator {
  Future<FourPillars> calculate(CalendarSnapshot snapshot);
}
