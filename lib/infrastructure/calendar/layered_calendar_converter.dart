import '../../domain/entities/bazi_request.dart';
import '../../domain/entities/calendar_snapshot.dart';
import '../../domain/entities/lunar_date.dart';
import '../../domain/services/calendar_converter.dart';
import '../../domain/services/lunar_solar_mapper.dart';
import '../../domain/value_objects/calendar_precision.dart';
import '../../domain/value_objects/calendar_type.dart';

class LayeredCalendarConverter implements CalendarConverter {
  const LayeredCalendarConverter({
    required LunarSolarMapper lunarSolarMapper,
  }) : _lunarSolarMapper = lunarSolarMapper;

  final LunarSolarMapper _lunarSolarMapper;

  @override
  Future<CalendarSnapshot> resolve(BaziRequest request) async {
    // 当农历输入时，先尝试调用真实的农历→公历映射器；
    // 映射器返回 null 时降级为 placeholder 直读。
    if (request.calendarType == CalendarType.lunar) {
      final lunarDate = LunarDate(
        year: request.lunarYear,
        month: request.lunarMonth,
        day: request.lunarDay,
        isLeapMonth: request.isLeapMonth,
      );

      final solarDateTime = await _lunarSolarMapper.solarFromLunar(lunarDate);
      if (solarDateTime != null) {
        return CalendarSnapshot(
          request: request,
          solarDateTime: solarDateTime,
          lunarDate: lunarDate,
          precision: CalendarPrecision.exact,
        );
      }

      return CalendarSnapshot(
        request: request,
        solarDateTime: request.solarDateTime,
        lunarDate: lunarDate,
        precision: CalendarPrecision.placeholder,
      );
    }

    // 公历输入时尝试反查农历，映射器不可用时降级为近似。
    final lunarDate =
        await _lunarSolarMapper.lunarFromSolar(request.solarDateTime);
    if (lunarDate != null) {
      return CalendarSnapshot(
        request: request,
        solarDateTime: request.solarDateTime,
        lunarDate: lunarDate,
        precision: CalendarPrecision.exact,
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
