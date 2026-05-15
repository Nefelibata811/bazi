import '../entities/bazi_request.dart';
import '../entities/calendar_snapshot.dart';

abstract class CalendarConverter {
  Future<CalendarSnapshot> resolve(BaziRequest request);
}
