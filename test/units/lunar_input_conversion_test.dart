// 文件：单元测试 — 农历录入conversion
//
// 验证 农历录入conversion 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:bazi_app/infrastructure/calendar/chart_datetime_resolver.dart';
import 'package:bazi_app/infrastructure/calendar/lunar_calendar_converter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/lunar.dart';

void main() {
  test('农历1974-10-25 05:00 对应公历约 1974-12-08', () {
    final solar = Lunar.fromYmdHms(1974, 10, 25, 5, 0, 0).getSolar();
    expect(solar.getYear(), 1974);
    expect(solar.getMonth(), 12);
    expect(solar.getDay(), 8);
  });

  test('农历2004-7-2 23:30 对应公历约 2004-8-17', () {
    final solar = Lunar.fromYmdHms(2004, 7, 2, 23, 30, 0).getSolar();
    expect(solar.getYear(), 2004);
    expect(solar.getMonth(), 8);
    expect(solar.getDay(), 17);
  });

  test('未同步 solarDateTime 时 clockLocal 仍按农历换算', () {
    final request = BaziRequest(
      calendarType: CalendarType.lunar,
      gender: Gender.male,
      solarDateTime: DateTime(2026, 5, 26, 23, 30),
      lunarYear: 2004,
      lunarMonth: 7,
      lunarDay: 2,
      isLeapMonth: false,
    );
    final clock = ChartDateTimeResolver.clockLocal(request);
    expect(clock.year, 2004);
    expect(clock.month, 8);
    expect(clock.day, 17);
    expect(clock.hour, 23);
    expect(clock.minute, 30);
  });

  test('LunarCalendarConverter 农历请求快照公历与农历一致', () async {
    final request = BaziRequest(
      calendarType: CalendarType.lunar,
      gender: Gender.male,
      solarDateTime: DateTime(2026, 5, 26, 5, 0),
      lunarYear: 1974,
      lunarMonth: 10,
      lunarDay: 25,
      isLeapMonth: false,
    );
    final snapshot = await const LunarCalendarConverter().resolve(request);
    expect(snapshot.solarDateTime.year, 1974);
    expect(snapshot.solarDateTime.month, 12);
    expect(snapshot.solarDateTime.day, 8);
    expect(snapshot.clockDateTime!.year, 1974);
    expect(snapshot.lunarDate.year, 1974);
    expect(snapshot.lunarDate.month, 10);
    expect(snapshot.lunarDate.day, 25);
  });
}
