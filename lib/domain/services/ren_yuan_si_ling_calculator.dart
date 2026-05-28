// 文件：人元元司lingcalculator
//
// 路径：`lib/domain/services/ren_yuan_si_ling_calculator.dart`。
//
import '../entities/ren_yuan_si_ling.dart';
import '../value_objects/si_ling_version.dart';

abstract class RenYuanSiLingCalculator {
  Future<RenYuanSiLing?> calculate({
    required DateTime solarDateTime,
    required String monthBranch,
    SiLingVersion version = SiLingVersion.common,
  });
}
