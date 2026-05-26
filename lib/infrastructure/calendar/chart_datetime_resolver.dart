import 'package:lunar/lunar.dart';

import '../../domain/entities/bazi_request.dart';
import '../../domain/entities/true_solar_time_info.dart';
import '../../domain/services/true_solar_time_calculator.dart';
import '../../domain/value_objects/calendar_type.dart';
import 'astro_true_solar_time_calculator.dart';

/// 排盘用时刻：农历录入先换算为公历钟表时刻，再按需应用真太阳时。
class ChartDateTimeResolver {
  const ChartDateTimeResolver._();

  static const TrueSolarTimeCalculator _calculator = AstroTrueSolarTimeCalculator();

  /// 用户钟表时刻（农历录入时由农历年月日 + 时分得到，不依赖未同步的 [BaziRequest.solarDateTime] 年月日）。
  static DateTime clockLocal(BaziRequest request) {
    if (request.calendarType == CalendarType.solar) {
      return request.solarDateTime;
    }
    final month =
        request.isLeapMonth ? -request.lunarMonth : request.lunarMonth;
    final solar = Lunar.fromYmdHms(
      request.lunarYear,
      month,
      request.lunarDay,
      request.solarDateTime.hour,
      request.solarDateTime.minute,
      0,
    ).getSolar();
    return DateTime(
      solar.getYear(),
      solar.getMonth(),
      solar.getDay(),
      request.solarDateTime.hour,
      request.solarDateTime.minute,
    );
  }

  static DateTime resolve(BaziRequest request) {
    final clock = clockLocal(request);
    if (!request.useTrueSolarTime || request.longitude == null) {
      return clock;
    }
    return _calculator.toTrueSolarDateTime(
      clockLocal: clock,
      longitude: request.longitude!,
      standardMeridian: request.standardMeridian,
    );
  }

  static TrueSolarTimeInfo? resolveInfo(BaziRequest request) {
    if (!request.useTrueSolarTime || request.longitude == null) {
      return null;
    }
    final name = request.birthPlaceName?.trim();
    return _calculator.computeInfo(
      clockLocal: clockLocal(request),
      longitude: request.longitude!,
      birthPlaceName:
          name != null && name.isNotEmpty ? name : '东经${request.longitude!.toStringAsFixed(2)}°',
      standardMeridian: request.standardMeridian,
    );
  }
}
