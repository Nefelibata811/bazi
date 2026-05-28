// 文件：单元测试 — 农历真公历历法
//
// 验证 农历真公历历法 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:bazi_app/infrastructure/calendar/chart_datetime_resolver.dart';
import 'package:bazi_app/infrastructure/calendar/lunar_eight_char_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/lunar.dart';

void main() {
  test('农历录入+真太阳跨公历日界与日柱按换算后公历时刻一致', () {
    final clock = DateTime(1990, 6, 15, 1, 30);
    final chartTime = ChartDateTimeResolver.resolve(
      BaziRequest(
        calendarType: CalendarType.lunar,
        gender: Gender.male,
        solarDateTime: clock,
        lunarYear: 1990,
        lunarMonth: 5,
        lunarDay: 23,
        isLeapMonth: false,
        useTrueSolarTime: true,
        longitude: 75,
      ),
    );
    expect(chartTime.day, 14);
    expect(chartTime.hour, 22);

    final lunarEc = LunarEightCharFactory.eightCharFromRequest(
      BaziRequest(
        calendarType: CalendarType.lunar,
        gender: Gender.male,
        solarDateTime: clock,
        lunarYear: 1990,
        lunarMonth: 5,
        lunarDay: 23,
        isLeapMonth: false,
        useTrueSolarTime: true,
        longitude: 75,
      ),
    );
    final solarEc = Solar.fromYmdHms(
      chartTime.year,
      chartTime.month,
      chartTime.day,
      chartTime.hour,
      chartTime.minute,
      0,
    ).getLunar().getEightChar();

    expect(lunarEc.getDayGan(), solarEc.getDayGan());
    expect(lunarEc.getDayZhi(), solarEc.getDayZhi());
    expect(lunarEc.getTimeGan(), solarEc.getTimeGan());
    expect(lunarEc.getTimeZhi(), solarEc.getTimeZhi());
  });
}
