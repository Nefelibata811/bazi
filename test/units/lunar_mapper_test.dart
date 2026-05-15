import 'package:bazi_app/domain/entities/lunar_date.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bazi_app/infrastructure/calendar/basic_lunar_solar_mapper.dart';

void main() {
  const mapper = BasicLunarSolarMapper();

  group('农历映射器 BasicLunarSolarMapper', () {
    group('公历 → 农历（lunarFromSolar）', () {
      test('2024-01-01 → 癸卯年 十一月二十', () async {
        final lunar = await mapper.lunarFromSolar(DateTime(2024, 1, 1));
        expect(lunar, isNotNull);
        expect(lunar!.year, 2023);
        expect(lunar.month, 11);
        expect(lunar.day, 20);
        expect(lunar.isLeapMonth, false);
      });

      test('2024-02-10 → 甲辰年 正月初一', () async {
        final lunar = await mapper.lunarFromSolar(DateTime(2024, 2, 10));
        expect(lunar, isNotNull);
        expect(lunar!.year, 2024);
        expect(lunar.month, 1);
        expect(lunar.day, 1);
        expect(lunar.isLeapMonth, false);
      });

      test('2024-06-10 → 甲辰年 五月初五（端午节）', () async {
        final lunar = await mapper.lunarFromSolar(DateTime(2024, 6, 10));
        expect(lunar, isNotNull);
        expect(lunar!.year, 2024);
        expect(lunar.month, 5);
        expect(lunar.day, 5);
      });

      test('2000-01-01 → 己卯年 十一月廿五', () async {
        final lunar = await mapper.lunarFromSolar(DateTime(2000, 1, 1));
        expect(lunar, isNotNull);
        expect(lunar!.year, 1999);
        expect(lunar.month, 11);
        expect(lunar.day, 25);
      });

      test('1984-02-02 → 癸亥年 正月初一', () async {
        final lunar = await mapper.lunarFromSolar(DateTime(1984, 2, 2));
        expect(lunar, isNotNull);
        expect(lunar!.year, 1984);
        expect(lunar.month, 1);
        expect(lunar.day, 1);
      });
    });

    group('农历 → 公历（solarFromLunar）', () {
      test('2024 正月初一 → 2024-02-10', () async {
        final solar = await mapper.solarFromLunar(
          const LunarDate(year: 2024, month: 1, day: 1, isLeapMonth: false),
        );
        expect(solar, isNotNull);
        expect(solar!.year, 2024);
        expect(solar.month, 2);
        expect(solar.day, 10);
      });

      test('2024 五月初五 → 2024-06-10', () async {
        final solar = await mapper.solarFromLunar(
          const LunarDate(year: 2024, month: 5, day: 5, isLeapMonth: false),
        );
        expect(solar, isNotNull);
        expect(solar!.year, 2024);
        expect(solar.month, 6);
        expect(solar.day, 10);
      });

      test('1984 正月初一 → 1984-02-02', () async {
        final solar = await mapper.solarFromLunar(
          const LunarDate(year: 1984, month: 1, day: 1, isLeapMonth: false),
        );
        expect(solar, isNotNull);
        expect(solar!.year, 1984);
        expect(solar.month, 2);
        expect(solar.day, 2);
      });
    });

    group('公历 ↔ 农历往返测试', () {
      final dates = [
        DateTime(2024, 2, 10),
        DateTime(2024, 6, 10),
        DateTime(2024, 1, 1),
        DateTime(2020, 1, 25),
        DateTime(2000, 1, 1),
        DateTime(1984, 2, 2),
      ];

      for (final dt in dates) {
        test('公→农→公 往返 ${dt.toIso8601String().split('T').first}', () async {
          final lunar = await mapper.lunarFromSolar(dt);
          expect(lunar, isNotNull);

          final back = await mapper.solarFromLunar(lunar!);
          expect(back, isNotNull);
          expect(back!.year, dt.year);
          expect(back.month, dt.month);
          expect(back.day, dt.day);
        });
      }
    });

    group('边界情况', () {
      test('范围外年份返回 null', () async {
        final lunar = await mapper.lunarFromSolar(DateTime(1800, 1, 1));
        expect(lunar, isNull);
      });

      test('闰月错误返回 null', () async {
        // 2024 年没有闰月，请求闰月应返回 null
        final solar = await mapper.solarFromLunar(
          const LunarDate(year: 2024, month: 3, day: 1, isLeapMonth: true),
        );
        expect(solar, isNull);
      });

      test('农历年边界的公历日期', () async {
        // 农历 2023 年最后一天
        final lunar = await mapper.lunarFromSolar(DateTime(2024, 2, 9));
        expect(lunar, isNotNull);
        expect(lunar!.year, 2023);
        expect(lunar.month, 12);

        // 农历 2024 年第一天
        final lunar2 = await mapper.lunarFromSolar(DateTime(2024, 2, 10));
        expect(lunar2, isNotNull);
        expect(lunar2!.year, 2024);
        expect(lunar2.month, 1);
      });
    });
  });
}
