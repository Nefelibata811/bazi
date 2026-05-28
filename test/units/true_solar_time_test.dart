// 文件：单元测试 — 真公历time
//
// 验证 真公历time 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/infrastructure/calendar/astro_true_solar_time_calculator.dart';
import 'package:bazi_app/infrastructure/calendar/chart_datetime_resolver.dart';
import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calc = AstroTrueSolarTimeCalculator();

  test('北京经度订正约为负（真太阳时早于钟表）', () {
    final clock = DateTime(2024, 6, 21, 12, 0);
    final trueSolar = calc.toTrueSolarDateTime(
      clockLocal: clock,
      longitude: 116.4074,
    );
    expect(trueSolar.isBefore(clock), isTrue);
  });

  test('乌鲁木齐经度订正明显偏西', () {
    final clock = DateTime(2024, 6, 21, 12, 0);
    final beijing = calc.toTrueSolarDateTime(
      clockLocal: clock,
      longitude: 116.4074,
    );
    final urumqi = calc.toTrueSolarDateTime(
      clockLocal: clock,
      longitude: 87.6168,
    );
    expect(urumqi.isBefore(beijing), isTrue);
  });

  test('ChartDateTimeResolver 关闭时返回钟表时间', () {
    final clock = DateTime(2000, 1, 1, 8, 30);
    final request = BaziRequest(
      calendarType: CalendarType.solar,
      gender: Gender.male,
      solarDateTime: clock,
      lunarYear: 2000,
      lunarMonth: 1,
      lunarDay: 1,
      isLeapMonth: false,
      useTrueSolarTime: false,
    );
    expect(ChartDateTimeResolver.resolve(request), clock);
  });

  test('ChartDateTimeResolver 开启时使用真太阳时', () {
    final clock = DateTime(2000, 1, 1, 12, 0);
    final request = BaziRequest(
      calendarType: CalendarType.solar,
      gender: Gender.male,
      solarDateTime: clock,
      lunarYear: 2000,
      lunarMonth: 1,
      lunarDay: 1,
      isLeapMonth: false,
      useTrueSolarTime: true,
      longitude: 87.6168,
      birthPlaceName: '乌鲁木齐市',
    );
    final resolved = ChartDateTimeResolver.resolve(request);
    expect(resolved, isNot(clock));
  });
}
