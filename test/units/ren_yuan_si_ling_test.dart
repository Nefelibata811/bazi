// 文件：单元测试 — 人元元司ling
//
// 验证 人元元司ling 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/domain/value_objects/si_ling_version.dart';
import 'package:bazi_app/infrastructure/calendar/astro_ren_yuan_si_ling_calculator.dart';
import 'package:bazi_app/infrastructure/calendar/astro_solar_term_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = AstroRenYuanSiLingCalculator(
    solarTermProvider: AstroSolarTermProvider(),
  );

  test('寅月出生后若干天司令为戊土或艮土系', () async {
    // 2024 立春后约 3 天，寅月常用表第一段为戊土 7 天
    final result = await calculator.calculate(
      solarDateTime: DateTime(2024, 2, 7, 12, 0),
      monthBranch: '寅',
      version: SiLingVersion.common,
    );
    expect(result, isNotNull);
    expect(result!.monthBranch, '寅');
    expect(result.stem, '戊');
    expect(result.daysSinceJie, greaterThan(0));
    expect(result.daysSinceJie, lessThan(7));
  });
}
