import '../../domain/entities/lunar_date.dart';
import '../../domain/services/julian_day.dart';
import '../../domain/services/lunar_solar_mapper.dart';

// 每一年 4 字节编码农历信息。
// bits 0-11: 按月序标记大小月（1=大月30天, 0=小月29天），正月为最低位。
// bits 12-15: 闰月月份（0=无闰月）。
// bits 16-19: 闰月大小（1=大, 0=小）。
// bits 20-23: 该农历年正月初一的公历月份。
// bits 24-28: 该农历年正月初一的公历日期。
class BasicLunarSolarMapper implements LunarSolarMapper {
  const BasicLunarSolarMapper();

  static const _startYear = 1900;
  static const _yearCodes = <int>[
    0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0,
    0x09ad0, 0x055d2, 0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540,
    0x0d6a0, 0x0ada2, 0x095b0, 0x14977, 0x04970, 0x0a4b0, 0x0b4b5, 0x06a50,
    0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, 0x06566, 0x0d4a0,
    0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
    0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2,
    0x0a950, 0x0b557, 0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573,
    0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, 0x0aea6, 0x0ab50, 0x04b60, 0x0aae4,
    0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, 0x096d0, 0x04dd5,
    0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
    0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46,
    0x0ab60, 0x09570, 0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58,
    0x055c0, 0x0ab60, 0x096d5, 0x092e0, 0x0c960, 0x0d954, 0x0d4a0, 0x0da50,
    0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, 0x0a950, 0x0b4a0,
    0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
    0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260,
    0x0ea65, 0x0d530, 0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0,
    0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, 0x0b5a0, 0x056d0, 0x055b2, 0x049b0,
    0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, 0x14b63, 0x09370,
    0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06aa0, 0x1a6c4, 0x0aae0,
    0x092e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0,
    0x0a6d0, 0x055d4, 0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50,
    0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, 0x0b273, 0x06930, 0x07337, 0x06aa0,
    0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, 0x0e968, 0x0d520,
    0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a4d0, 0x0d150, 0x0f252,
    0x0d520,
  ];

  @override
  Future<DateTime?> solarFromLunar(LunarDate lunarDate) async {
    if (lunarDate.year < _startYear ||
        lunarDate.year >= _startYear + _yearCodes.length) {
      return null;
    }

    final yearIndex = lunarDate.year - _startYear;
    final code = _yearCodes[yearIndex];
    final leapMonth = _leapMonth(code);
    final lunarMonth = lunarDate.month;

    // 闰月有效性检查
    if (lunarDate.isLeapMonth && lunarMonth != leapMonth) {
      return null;
    }

    // 找到农历正月初一所对应的公历日期
    final firstDayMonth = (code >> 20) & 0xF;
    final firstDayDay = (code >> 24) & 0x1F;
    final firstDay = DateTime(lunarDate.year, firstDayMonth, firstDayDay);

    // 从正月初一到目标农历月日，逐月累加天数
    int daysOffset = lunarDate.day - 1;
    for (int m = 1; m < lunarMonth; m++) {
      daysOffset += _monthDays(code, m);
    }
    // 如果目标月是闰月且该年有闰月且在闰月之后，需要加上闰月天数
    bool needLeap = lunarDate.isLeapMonth ||
        (leapMonth > 0 && lunarMonth > leapMonth);
    if (needLeap && leapMonth > 0 && lunarMonth > leapMonth) {
      daysOffset += _leapMonthDays(code);
    }
    // 如果目标是闰月当月，需要先加完前面所有月份再加闰月
    if (lunarDate.isLeapMonth) {
      daysOffset += _monthDays(code, lunarMonth);
    }

    final jd = JulianDay.fromDateTime(firstDay) + daysOffset;
    return JulianDay.toDateTime(jd);
  }

  @override
  Future<LunarDate?> lunarFromSolar(DateTime solarDateTime) async {
    if (solarDateTime.year < _startYear ||
        solarDateTime.year >= _startYear + _yearCodes.length + 1) {
      return null;
    }

    final jd = JulianDay.fromDateTime(solarDateTime);

    for (int yi = _startYear; yi < _startYear + _yearCodes.length; yi++) {
      final yearIndex = yi - _startYear;
      final code = _yearCodes[yearIndex];

      final firstDayMonth = (code >> 20) & 0xF;
      final firstDayDay = (code >> 24) & 0x1F;
      final firstDay = DateTime(yi, firstDayMonth, firstDayDay);
      final firstJd = JulianDay.fromDateTime(firstDay);

      final nextCode = yearIndex + 1 < _yearCodes.length
          ? _yearCodes[yearIndex + 1]
          : 0x04bd8;
      final nextFirstMonth = (nextCode >> 20) & 0xF;
      final nextFirstDay = (nextCode >> 24) & 0x1F;
      final nextFirstDate = DateTime(yi + 1, nextFirstMonth, nextFirstDay);
      final nextFirstJd = JulianDay.fromDateTime(nextFirstDate);

      if (jd < firstJd || jd >= nextFirstJd) continue;

      // 在这一农历年内，从正月开始逐月查找
      final daysFromFirst = jd - firstJd;
      int accumulated = 0;
      final leapMonth = _leapMonth(code);

      for (int m = 1; m <= 12; m++) {
        final mDays = _monthDays(code, m);
        if (daysFromFirst < accumulated + mDays) {
          return LunarDate(
            year: yi,
            month: m,
            day: daysFromFirst - accumulated + 1,
            isLeapMonth: false,
          );
        }
        accumulated += mDays;

        if (leapMonth == m) {
          final leapDays = _leapMonthDays(code);
          if (daysFromFirst < accumulated + leapDays) {
            return LunarDate(
              year: yi,
              month: m,
              day: daysFromFirst - accumulated + 1,
              isLeapMonth: true,
            );
          }
          accumulated += leapDays;
        }
      }
      // 落到了最后一个月
      final lastMonthDays = _monthDays(code, 12);
      return LunarDate(
        year: yi,
        month: 12,
        day: (daysFromFirst - accumulated + lastMonthDays + 1),
        isLeapMonth: false,
      );
    }

    return null;
  }

  int _monthDays(int code, int month) {
    return ((code >> (month - 1)) & 1) == 1 ? 30 : 29;
  }

  int _leapMonth(int code) {
    return (code >> 12) & 0xF;
  }

  int _leapMonthDays(int code) {
    return ((code >> 16) & 1) == 1 ? 30 : 29;
  }
}
