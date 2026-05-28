// 文件：approx公历节气提供者
//
// 历法算法：八字排盘核心计算。
// 路径：`lib/infrastructure/calendar/approx_solar_term_provider.dart`。
//
import '../../domain/constants/solar_term_constants.dart';
import '../../domain/entities/solar_term_info.dart';
import '../../domain/services/solar_term_provider.dart';

/// 类 `ApproxSolarTermProvider`：实现 Approx Solar Term Provider 相关逻辑。
class ApproxSolarTermProvider implements SolarTermProvider {
  const ApproxSolarTermProvider();

  // 24 节气中，奇数位（小寒=0、立春=2、惊蛰=4...）为"节"，
  // 对应一个地支月，依次为丑月(0)-寅月(1)-卯月(2)-...-子月(11)。
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

  @override
  Future<List<SolarTermInfo>> termsOfYear(int year) async {
    // 当前版本使用公历近似日期生成节气，精度为 approximate。
    // 后续接入天文算法时只需替换此方法的计算逻辑。
    return List<SolarTermInfo>.generate(
      SolarTermConstants.names.length,
      (index) {
        final entry = SolarTermConstants.approximateMonthDays[index];
        final month = entry[0];
        final day = entry[1];

        return SolarTermInfo(
          name: SolarTermConstants.names[index],
          occurredAt: DateTime(year, month, day),
          index: index,
          termMonth: termMonthMapping[index],
        );
      },
    );
  }

  @override
  Future<List<SolarTermInfo>> surroundingTerms(DateTime moment) async {
    // 取前后两年节气表，从中截取当前时间附近 6 个节气，
    // 用于月柱判断和起运推算。
    final yearTerms = await termsOfYear(moment.year);
    final prevYearTerms = await termsOfYear(moment.year - 1);
    final nextYearTerms = await termsOfYear(moment.year + 1);
    final allTerms = [...prevYearTerms, ...yearTerms, ...nextYearTerms];
    allTerms.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    final index = allTerms.indexWhere((t) => t.occurredAt.isAfter(moment));
    final start = (index - 3).clamp(0, allTerms.length - 6);
    return allTerms.sublist(start, (start + 6).clamp(0, allTerms.length));
  }
}
