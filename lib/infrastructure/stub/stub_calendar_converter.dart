import '../../domain/entities/bazi_request.dart';
import '../../domain/entities/calendar_snapshot.dart';
import '../../domain/entities/lunar_date.dart';
import '../../domain/services/calendar_converter.dart';
import '../../domain/value_objects/calendar_precision.dart';
import '../../domain/value_objects/calendar_type.dart';

class StubCalendarConverter implements CalendarConverter {
  @override
  Future<CalendarSnapshot> resolve(BaziRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    if (request.calendarType == CalendarType.lunar) {
      return CalendarSnapshot(
        request: request,
        solarDateTime: request.solarDateTime,
        lunarDate: LunarDate(
          year: request.lunarYear,
          month: request.lunarMonth,
          day: request.lunarDay,
          isLeapMonth: request.isLeapMonth,
        ),
        precision: CalendarPrecision.placeholder,
      );
    }

    return CalendarSnapshot(
      request: request,
      solarDateTime: request.solarDateTime,
      lunarDate: LunarDate(
        year: request.solarDateTime.year,
        month: request.solarDateTime.month,
        day: request.solarDateTime.day,
        isLeapMonth: false,
      ),
      precision: CalendarPrecision.approximate,
    );
  }
}
