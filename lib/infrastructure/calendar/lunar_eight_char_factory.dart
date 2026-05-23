import 'package:lunar/lunar.dart';

import '../../domain/entities/bazi_request.dart';
import '../../domain/value_objects/calendar_type.dart';

/// 从 [BaziRequest] 构建 lunar [Lunar] / [EightChar] 并应用晚子时流派。
class LunarEightCharFactory {
  const LunarEightCharFactory._();

  static Lunar lunarFromRequest(BaziRequest request) {
    if (request.calendarType == CalendarType.solar) {
      return Solar.fromYmdHms(
        request.solarDateTime.year,
        request.solarDateTime.month,
        request.solarDateTime.day,
        request.solarDateTime.hour,
        request.solarDateTime.minute,
        0,
      ).getLunar();
    }
    final month =
        request.isLeapMonth ? -request.lunarMonth : request.lunarMonth;
    return Lunar.fromYmdHms(
      request.lunarYear,
      month,
      request.lunarDay,
      request.solarDateTime.hour,
      request.solarDateTime.minute,
      0,
    );
  }

  static EightChar eightCharFromRequest(BaziRequest request) {
    final ec = lunarFromRequest(request).getEightChar();
    ec.setSect(request.baziSect.lunarSect);
    return ec;
  }
}
