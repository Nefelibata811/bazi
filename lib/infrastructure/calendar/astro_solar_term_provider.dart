import 'dart:math';

import '../../domain/constants/solar_term_constants.dart';
import '../../domain/entities/solar_term_info.dart';
import '../../domain/services/julian_day.dart';
import '../../domain/services/solar_term_provider.dart';

class AstroSolarTermProvider implements SolarTermProvider {
  const AstroSolarTermProvider();

  // 节类节气与月支映射：小寒=0→丑月(11), 立春=2→寅月(0), 惊蛰=4→卯月(1), ...
  static const termMonthMapping = {
    0: 11,
    2: 0,
    4: 1,
    6: 2,
    8: 3,
    10: 4,
    12: 5,
    14: 6,
    16: 7,
    18: 8,
    20: 9,
    22: 10,
  };

  static const _j2000 = 2451545.0;
  static const _pi = 3.141592653589793;

  @override
  Future<List<SolarTermInfo>> termsOfYear(int year) async {
    return List<SolarTermInfo>.generate(
      SolarTermConstants.names.length,
      (index) {
        final jd = _solarTermJD(year, index);
        final dateTime = JulianDay.toDateTimeExact(jd);

        return SolarTermInfo(
          name: SolarTermConstants.names[index],
          occurredAt: dateTime,
          index: index,
          termMonth: termMonthMapping[index],
        );
      },
    );
  }

  @override
  Future<List<SolarTermInfo>> surroundingTerms(DateTime moment) async {
    final yearTerms = await termsOfYear(moment.year);
    final prevYearTerms = await termsOfYear(moment.year - 1);
    final nextYearTerms = await termsOfYear(moment.year + 1);
    final allTerms = [...prevYearTerms, ...yearTerms, ...nextYearTerms];
    allTerms.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    final index = allTerms.indexWhere((t) => t.occurredAt.isAfter(moment));
    final start = (index - 3).clamp(0, allTerms.length - 6);
    return allTerms.sublist(start, (start + 6).clamp(0, allTerms.length));
  }

  // 以牛顿迭代法求取太阳视黄经到达目标角度时的儒略日。
  // 算法来源：Meeus《Astronomical Algorithms》第 27 章，VSOP 近似公式。
  double _solarTermJD(int year, int index) {
    // 每个节气间隔 15°，小寒起于 285°。
    final targetLng = (285.0 + 15.0 * index) % 360.0;

    // 初始估计：使用节气常见公历近似日期，离真实值通常不到 1 天。
    final approx = SolarTermConstants.approximateMonthDays[index];
    final baseDt = DateTime(year, approx[0], approx[1]);
    var jd = JulianDay.fromDateTimeExact(baseDt);

    // 牛顿迭代，精度目标 < 0.0001°（约 8.6 秒）。
    for (int i = 0; i < 6; i++) {
      final lng = _sunApparentLongitude(jd);
      var diff = targetLng - lng;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;

      if (diff.abs() < 0.00005) break;

      jd += diff / _dailyMeanMotion(jd);
    }

    return jd;
  }

  // 太阳视黄经（VSOP 近似，含光行差与章动修正）。
  double _sunApparentLongitude(double jd) {
    final T = (jd - _j2000) / 36525.0;

    // 太阳平黄经
    final L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T;

    // 太阳平近点角
    final M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T;

    final Mr = M * _pi / 180.0;
    final sinM = sin(Mr);
    final sin2M = sin(2 * Mr);
    final sin3M = sin(3 * Mr);

    // 中心差
    final C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sinM +
        (0.019993 - 0.000101 * T) * sin2M +
        0.000289 * sin3M;

    // 黄经章动（简化项，约 ±20"）
    final omega = 125.04 - 1934.136 * T;
    final nutation = -0.00479 * sin(omega * _pi / 180.0);

    // 光行差
    final aberration = -0.00569;

    var longitude = L0 + C + nutation + aberration;
    longitude = longitude % 360.0;
    if (longitude < 0) longitude += 360.0;

    return longitude;
  }

  // 太阳每日平均运动速率（度/日），含中心差一阶导数近似。
  double _dailyMeanMotion(double jd) {
    final T = (jd - _j2000) / 36525.0;
    const baseMotion = 36000.76983 / 36525.0;
    final M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T;
    final Mr = M * _pi / 180.0;
    final dC = (1.914602 - 0.004817 * T) * cos(Mr) *
            (35999.05029 / 36525.0 * _pi / 180.0) +
        (0.019993 - 0.000101 * T) * cos(2 * Mr) *
            (2 * 35999.05029 / 36525.0 * _pi / 180.0);

    return baseMotion + dC;
  }
}
