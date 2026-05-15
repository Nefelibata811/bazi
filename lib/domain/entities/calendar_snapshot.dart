import 'bazi_request.dart';
import 'lunar_date.dart';
import '../value_objects/calendar_precision.dart';

class CalendarSnapshot {
  const CalendarSnapshot({
    required this.request,
    required this.solarDateTime,
    required this.lunarDate,
    required this.precision,
  });

  final BaziRequest request;
  final DateTime solarDateTime;
  final LunarDate lunarDate;
  final CalendarPrecision precision;

  int get lunarYear => lunarDate.year;
  int get lunarMonth => lunarDate.month;
  int get lunarDay => lunarDate.day;
  bool get isLeapMonth => lunarDate.isLeapMonth;
}
