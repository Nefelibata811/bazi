// 文件：真公历timecalculator
//
// 路径：`lib/domain/services/true_solar_time_calculator.dart`。
//
import '../entities/true_solar_time_info.dart';

/// 将出生地钟表时间换算为真太阳时（用于排盘时辰）。
abstract class TrueSolarTimeCalculator {
  const TrueSolarTimeCalculator();

  /// 中国标准时区基准经线（东经 120°，UTC+8）。
  static const double chinaStandardMeridian = 120.0;

  DateTime toTrueSolarDateTime({
    required DateTime clockLocal,
    required double longitude,
    double standardMeridian = chinaStandardMeridian,
  });

  TrueSolarTimeInfo computeInfo({
    required DateTime clockLocal,
    required double longitude,
    required String birthPlaceName,
    double standardMeridian = chinaStandardMeridian,
  });
}
