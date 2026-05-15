import 'package:lunar/lunar.dart';

import '../../../domain/entities/bazi_request.dart';
import '../../../domain/entities/calendar_snapshot.dart';
import '../../../domain/entities/lunar_date.dart';
import '../../../domain/services/calendar_converter.dart';
import '../../../domain/value_objects/calendar_precision.dart';
import '../../../domain/value_objects/calendar_type.dart';

class LunarCalendarConverter implements CalendarConverter {
  const LunarCalendarConverter();

  @override
  Future<CalendarSnapshot> resolve(BaziRequest request) async {
    final Solar solar;
    final Lunar lunar;

    if (request.calendarType == CalendarType.solar) {
      solar = Solar.fromYmdHms(
        request.solarDateTime.year,
        request.solarDateTime.month,
        request.solarDateTime.day,
        request.solarDateTime.hour,
        request.solarDateTime.minute,
        0,
      );
      lunar = solar.getLunar();
    } else {
      final month =
          request.isLeapMonth ? -request.lunarMonth : request.lunarMonth;
      lunar = Lunar.fromYmdHms(
        request.lunarYear,
        month,
        request.lunarDay,
        request.solarDateTime.hour,
        request.solarDateTime.minute,
        0,
      );
      solar = lunar.getSolar();
    }

    final rawMonth = lunar.getMonth();
    final isLeap = rawMonth < 0;

    return CalendarSnapshot(
      request: request,
      solarDateTime: DateTime(
        solar.getYear(),
        solar.getMonth(),
        solar.getDay(),
        request.solarDateTime.hour,
        request.solarDateTime.minute,
      ),
      lunarDate: LunarDate(
        year: lunar.getYear(),
        month: isLeap ? -rawMonth : rawMonth,
        day: lunar.getDay(),
        isLeapMonth: isLeap,
      ),
      precision: CalendarPrecision.exact,
    );
  }
}
