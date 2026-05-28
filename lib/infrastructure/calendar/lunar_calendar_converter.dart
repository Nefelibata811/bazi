// 文件：农历历法转换
//
// 历法算法：八字排盘核心计算。
// 路径：`lib/infrastructure/calendar/lunar_calendar_converter.dart`。
//
import 'package:lunar/lunar.dart';

import '../../../domain/entities/bazi_request.dart';
import '../../../domain/entities/calendar_snapshot.dart';
import '../../../domain/entities/lunar_date.dart';
import '../../../domain/services/calendar_converter.dart';
import '../../../domain/value_objects/calendar_precision.dart';
import 'chart_datetime_resolver.dart';

/// 类 `LunarCalendarConverter`：实现 Lunar Calendar Converter 相关逻辑。
class LunarCalendarConverter implements CalendarConverter {
  const LunarCalendarConverter();

  @override
  Future<CalendarSnapshot> resolve(BaziRequest request) async {
    final clock = ChartDateTimeResolver.clockLocal(request);
    final chartTime = ChartDateTimeResolver.resolve(request);
    final trueSolar = ChartDateTimeResolver.resolveInfo(request);
    final solar = Solar.fromYmdHms(
      chartTime.year,
      chartTime.month,
      chartTime.day,
      chartTime.hour,
      chartTime.minute,
      0,
    );
    final lunar = solar.getLunar();

    final rawMonth = lunar.getMonth();
    final isLeap = rawMonth < 0;

    return CalendarSnapshot(
      request: request,
      solarDateTime: chartTime,
      clockDateTime: clock,
      trueSolarTime: trueSolar,
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
