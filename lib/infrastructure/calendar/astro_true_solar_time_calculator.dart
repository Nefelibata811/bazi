import 'dart:math' as math;

import '../../domain/entities/true_solar_time_info.dart';
import '../../domain/services/true_solar_time_calculator.dart';

/// 真太阳时 = 标准时 + (当地经度 − 时区经线) × 4 分/度 + 时差（均时差）。
class AstroTrueSolarTimeCalculator implements TrueSolarTimeCalculator {
  const AstroTrueSolarTimeCalculator();

  @override
  DateTime toTrueSolarDateTime({
    required DateTime clockLocal,
    required double longitude,
    double standardMeridian = TrueSolarTimeCalculator.chinaStandardMeridian,
  }) {
    final totalMinutes = _totalCorrectionMinutes(
      clockLocal: clockLocal,
      longitude: longitude,
      standardMeridian: standardMeridian,
    );
    return _addMinutes(clockLocal, totalMinutes);
  }

  @override
  TrueSolarTimeInfo computeInfo({
    required DateTime clockLocal,
    required double longitude,
    required String birthPlaceName,
    double standardMeridian = TrueSolarTimeCalculator.chinaStandardMeridian,
  }) {
    final lonCorr = _longitudeCorrectionMinutes(longitude, standardMeridian);
    final eot = _equationOfTimeMinutes(clockLocal);
    final total = lonCorr + eot;
    final trueSolar = _addMinutes(clockLocal, total);
    return TrueSolarTimeInfo(
      birthPlaceName: birthPlaceName,
      longitude: longitude,
      clockDateTime: clockLocal,
      trueSolarDateTime: trueSolar,
      longitudeCorrectionMinutes: lonCorr,
      equationOfTimeMinutes: eot,
      totalCorrectionMinutes: total,
    );
  }

  /// 经度订正（分）：东经大于基准经线则真太阳时偏晚。
  static double _longitudeCorrectionMinutes(
    double longitude,
    double standardMeridian,
  ) =>
      (longitude - standardMeridian) * 4.0;

  /// 均时差（分），按公历日近似。
  static double _equationOfTimeMinutes(DateTime clockLocal) {
    final dayOfYear = _dayOfYear(clockLocal);
    final b = 2 * math.pi * (dayOfYear - 81) / 365.0;
    return 9.87 * math.sin(2 * b) -
        7.53 * math.cos(b) -
        1.5 * math.sin(b);
  }

  static int _dayOfYear(DateTime dt) {
    final start = DateTime(dt.year, 1, 1);
    return dt.difference(start).inDays + 1;
  }

  static double _totalCorrectionMinutes({
    required DateTime clockLocal,
    required double longitude,
    required double standardMeridian,
  }) {
    return _longitudeCorrectionMinutes(longitude, standardMeridian) +
        _equationOfTimeMinutes(clockLocal);
  }

  static DateTime _addMinutes(DateTime dt, double minutes) {
    final micros = (minutes * 60 * 1000000).round();
    return dt.add(Duration(microseconds: micros));
  }
}
