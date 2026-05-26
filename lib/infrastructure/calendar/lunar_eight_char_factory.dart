import 'package:lunar/lunar.dart';

import '../../domain/entities/bazi_request.dart';
import '../../domain/value_objects/calendar_type.dart';
import 'chart_datetime_resolver.dart';

/// 从 [BaziRequest] 构建 lunar [Lunar] / [EightChar] 并应用晚子时流派。
class LunarEightCharFactory {
  const LunarEightCharFactory._();

  static Lunar lunarFromRequest(BaziRequest request) {
    final chartTime = ChartDateTimeResolver.resolve(request);
    if (request.calendarType == CalendarType.solar ||
        (request.useTrueSolarTime && request.longitude != null)) {
      return Solar.fromYmdHms(
        chartTime.year,
        chartTime.month,
        chartTime.day,
        chartTime.hour,
        chartTime.minute,
        0,
      ).getLunar();
    }
    final month =
        request.isLeapMonth ? -request.lunarMonth : request.lunarMonth;
    return Lunar.fromYmdHms(
      request.lunarYear,
      month,
      request.lunarDay,
      chartTime.hour,
      chartTime.minute,
      0,
    );
  }

  static EightChar eightCharFromRequest(BaziRequest request) {
    final ec = lunarFromRequest(request).getEightChar();
    ec.setSect(request.baziSect.lunarSect);
    return ec;
  }
}
