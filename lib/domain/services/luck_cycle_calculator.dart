import '../entities/bazi_chart.dart';
import '../entities/bazi_request.dart';
import '../entities/calendar_snapshot.dart';
import '../entities/luck_cycle.dart';
import '../entities/solar_term_info.dart';

abstract class LuckCycleCalculator {
  Future<List<LuckCycle>> calculate({
    required BaziRequest request,
    required CalendarSnapshot calendarSnapshot,
    required BaziChart chart,
    required List<SolarTermInfo> solarTerms,
  });
}
