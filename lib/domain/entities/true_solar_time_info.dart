// 文件：真公历timeinfo
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/true_solar_time_info.dart`。
//
class TrueSolarTimeInfo {
  const TrueSolarTimeInfo({
    required this.birthPlaceName,
    required this.longitude,
    required this.clockDateTime,
    required this.trueSolarDateTime,
    required this.longitudeCorrectionMinutes,
    required this.equationOfTimeMinutes,
    required this.totalCorrectionMinutes,
  });

  final String birthPlaceName;
  final double longitude;
  final DateTime clockDateTime;
  final DateTime trueSolarDateTime;
  final double longitudeCorrectionMinutes;
  final double equationOfTimeMinutes;
  final double totalCorrectionMinutes;
}
