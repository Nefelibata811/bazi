import '../../domain/entities/bazi_request.dart';
import '../../domain/entities/true_solar_time_info.dart';
import '../../domain/services/true_solar_time_calculator.dart';
import 'astro_true_solar_time_calculator.dart';

/// 排盘用时刻：开启真太阳时时按出生地经度换算，否则用钟表时间。
class ChartDateTimeResolver {
  const ChartDateTimeResolver._();

  static const TrueSolarTimeCalculator _calculator = AstroTrueSolarTimeCalculator();

  static DateTime resolve(BaziRequest request) {
    if (!request.useTrueSolarTime || request.longitude == null) {
      return request.solarDateTime;
    }
    return _calculator.toTrueSolarDateTime(
      clockLocal: request.solarDateTime,
      longitude: request.longitude!,
      standardMeridian: request.standardMeridian,
    );
  }

  static TrueSolarTimeInfo? resolveInfo(BaziRequest request) {
    if (!request.useTrueSolarTime || request.longitude == null) {
      return null;
    }
    final name = request.birthPlaceName?.trim();
    return _calculator.computeInfo(
      clockLocal: request.solarDateTime,
      longitude: request.longitude!,
      birthPlaceName:
          name != null && name.isNotEmpty ? name : '东经${request.longitude!.toStringAsFixed(2)}°',
      standardMeridian: request.standardMeridian,
    );
  }
}
