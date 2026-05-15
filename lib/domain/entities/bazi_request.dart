import '../value_objects/calendar_type.dart';
import '../value_objects/gender.dart';

class BaziRequest {
  const BaziRequest({
    required this.calendarType,
    required this.gender,
    required this.solarDateTime,
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isLeapMonth,
    this.personName,
  });

  final CalendarType calendarType;
  final Gender gender;
  final DateTime solarDateTime;
  final int lunarYear;
  final int lunarMonth;
  final int lunarDay;
  final bool isLeapMonth;
  final String? personName;
}
