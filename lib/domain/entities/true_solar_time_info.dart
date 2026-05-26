/// 真太阳时换算结果（用于结果页展示）。
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
