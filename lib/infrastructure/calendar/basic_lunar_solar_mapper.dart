import 'package:lunar/lunar.dart';

import '../../domain/entities/lunar_date.dart';
import '../../domain/services/lunar_solar_mapper.dart';

/// 农历公历互转，委托 [lunar] 库与排盘引擎保持一致。
class BasicLunarSolarMapper implements LunarSolarMapper {
  const BasicLunarSolarMapper();

  @override
  Future<DateTime?> solarFromLunar(LunarDate lunarDate) async {
    if (lunarDate.year < 1900 || lunarDate.year > 2100) {
      return null;
    }
    try {
      final month =
          lunarDate.isLeapMonth ? -lunarDate.month : lunarDate.month;
      final lunar = Lunar.fromYmd(
        lunarDate.year,
        month,
        lunarDate.day,
      );
      final solar = lunar.getSolar();
      return DateTime(
        solar.getYear(),
        solar.getMonth(),
        solar.getDay(),
        solar.getHour(),
        solar.getMinute(),
        solar.getSecond(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LunarDate?> lunarFromSolar(DateTime solarDateTime) async {
    if (solarDateTime.year < 1900 || solarDateTime.year > 2100) {
      return null;
    }
    try {
      final solar = Solar.fromYmdHms(
        solarDateTime.year,
        solarDateTime.month,
        solarDateTime.day,
        solarDateTime.hour,
        solarDateTime.minute,
        solarDateTime.second,
      );
      final lunar = solar.getLunar();
      final month = lunar.getMonth();
      return LunarDate(
        year: lunar.getYear(),
        month: month.abs(),
        day: lunar.getDay(),
        isLeapMonth: month < 0,
      );
    } catch (_) {
      return null;
    }
  }
}
