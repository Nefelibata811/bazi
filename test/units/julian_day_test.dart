import 'package:bazi_app/domain/services/julian_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JulianDay', () {
    group('fromDateTime 公历 → 整数儒略日', () {
      // 基准点来自《天文算法》Meeus 已知数据。
      test('1900-01-01 → 2415020', () {
        final jd = JulianDay.fromDateTime(DateTime(1900, 1, 1));
        // Meeus 表给出 1900-01-01 12:00 TD ≈ 2415020.0
        expect(jd, 2415020);
      });

      test('1984-01-01 → 2445701', () {
        final jd = JulianDay.fromDateTime(DateTime(1984, 1, 1));
        // 1984-01-01 12:00 → 甲子年甲子日前 30 天
        // 预期值约为 2445701（标准历书值）
        expect(jd, 2445701);
      });

      test('2000-01-01 → 2451545', () {
        final jd = JulianDay.fromDateTime(DateTime(2000, 1, 1));
        // J2000.0 = 2451545.0，公历 2000-01-01 12:00
        expect(jd, 2451545);
      });

      test('2024-01-01 → 2460310', () {
        final jd = JulianDay.fromDateTime(DateTime(2024, 1, 1));
        expect(jd, 2460310);
      });

      test('闰年 2024-02-29 处理正确', () {
        final feb28 = JulianDay.fromDateTime(DateTime(2024, 2, 28));
        final feb29 = JulianDay.fromDateTime(DateTime(2024, 2, 29));
        final mar01 = JulianDay.fromDateTime(DateTime(2024, 3, 1));
        expect(feb29 - feb28, 1);
        expect(mar01 - feb29, 1);
      });

      test('连续两天差值为 1', () {
        final d1 = JulianDay.fromDateTime(DateTime(1999, 12, 31));
        final d2 = JulianDay.fromDateTime(DateTime(2000, 1, 1));
        expect(d2 - d1, 1);
      });

      test('同一年内逐日递增', () {
        for (int m = 1; m <= 12; m++) {
          for (int d = 1; d <= 28; d++) {
            final jd = JulianDay.fromDateTime(DateTime(2024, m, d));
            final jdNext = JulianDay.fromDateTime(DateTime(2024, m, d + 1));
            expect(jdNext - jd, 1);
          }
        }
      });
    });

    group('toDateTime 整数儒略日 → 公历（往返测试）', () {
      final dates = [
        DateTime(1900, 1, 1),
        DateTime(1950, 6, 15),
        DateTime(1984, 2, 4),
        DateTime(2000, 3, 21),
        DateTime(2024, 6, 21),
        DateTime(2024, 12, 31),
        DateTime(1999, 12, 31),
        DateTime(2000, 1, 1),
        DateTime(2100, 1, 1),
      ];

      for (final dt in dates) {
        test('往返 ${dt.year}-${dt.month}-${dt.day}', () {
          final jd = JulianDay.fromDateTime(dt);
          final back = JulianDay.toDateTime(jd);
          expect(back.year, dt.year);
          expect(back.month, dt.month);
          expect(back.day, dt.day);
        });
      }
    });

    group('fromDateTimeExact / toDateTimeExact 浮点儒略日', () {
      test('正午 12:00 的小数部分为 0', () {
        final dt = DateTime(2000, 1, 1, 12, 0, 0);
        final jd = JulianDay.fromDateTimeExact(dt);
        // J2000.0 = 2451545.0
        expect(jd, closeTo(2451545.0, 0.001));
      });

      test('00:00 的小数部分约 -0.5', () {
        final dt = DateTime(2000, 1, 1, 0, 0, 0);
        final jd = JulianDay.fromDateTimeExact(dt);
        expect(jd, closeTo(2451544.5, 0.001));
      });

      test('18:00 的小数部分约 +0.25', () {
        final dt = DateTime(2000, 1, 1, 18, 0, 0);
        final jdExt = JulianDay.fromDateTimeExact(dt);
        expect(jdExt, closeTo(2451545.25, 0.001));
      });

      test('浮点儒略日往返测试（精确到时/分/秒）', () {
        final original = DateTime(2024, 3, 20, 11, 6, 30);
        final jdExt = JulianDay.fromDateTimeExact(original);
        final back = JulianDay.toDateTimeExact(jdExt);
        expect(back.year, original.year);
        expect(back.month, original.month);
        expect(back.day, original.day);
        expect(back.hour, original.hour);
        expect(back.minute, original.minute);
        // 秒允许 ±2 舍入误差
        expect((back.second - original.second).abs(), lessThanOrEqualTo(2));
      });

      test('大范围往返测试（每 10 年取点）', () {
        for (int y = 1900; y <= 2100; y += 10) {
          for (int m = 1; m <= 12; m += 3) {
            final dt = DateTime(y, m, 15, 8, 30, 0);
            final jdExt = JulianDay.fromDateTimeExact(dt);
            final back = JulianDay.toDateTimeExact(jdExt);
            expect(back.year, dt.year);
            expect(back.month, dt.month);
            expect(back.day, dt.day);
            expect((back.hour - dt.hour).abs(), lessThanOrEqualTo(1));
            expect((back.minute - dt.minute).abs(), lessThanOrEqualTo(1));
          }
        }
      });
    });

    group('fromDateTimeExact 整数部分等于 fromDateTime', () {
      test('任意日期的整数部分一致性', () {
        final dates = [1900, 1950, 1984, 2000, 2024, 2100];
        for (final y in dates) {
          for (final m in [1, 3, 6, 9, 12]) {
            final dt = DateTime(y, m, 15);
            final intJd = JulianDay.fromDateTime(dt);
            final extJd = JulianDay.fromDateTimeExact(
                DateTime(y, m, 15, 12, 0, 0));
            expect(extJd.floor(), intJd);
          }
        }
      });
    });
  });
}
