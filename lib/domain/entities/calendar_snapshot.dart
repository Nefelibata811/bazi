import 'bazi_request.dart';
import 'lunar_date.dart';
import 'true_solar_time_info.dart';
import '../value_objects/calendar_precision.dart';

class CalendarSnapshot {
  const CalendarSnapshot({
    required this.request,
    required this.solarDateTime,
    required this.lunarDate,
    required this.precision,
    this.clockDateTime,
    this.trueSolarTime,
  });

  final BaziRequest request;
  /// 用于排盘的时刻（真太阳时开启时为换算后的时刻）。
  final DateTime solarDateTime;
  final LunarDate lunarDate;
  final CalendarPrecision precision;
  /// 用户录入的钟表时间；未开启真太阳时时与 [solarDateTime] 相同。
  final DateTime? clockDateTime;
  final TrueSolarTimeInfo? trueSolarTime;

  int get lunarYear => lunarDate.year;
  int get lunarMonth => lunarDate.month;
  int get lunarDay => lunarDate.day;
  bool get isLeapMonth => lunarDate.isLeapMonth;
}
