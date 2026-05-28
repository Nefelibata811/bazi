// 文件：神煞calculator
//
// 路径：`lib/domain/services/shensha_calculator.dart`。
//
import '../entities/bazi_chart.dart';
import '../entities/shensha_item.dart';
import '../value_objects/gender.dart';

abstract class ShenshaCalculator {
  Future<List<ShenshaItem>> calculate(
    BaziChart chart, {
    Gender? gender,
  });
}
