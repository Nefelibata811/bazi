// 文件：八字calculator
//
// 路径：`lib/domain/services/bazi_calculator.dart`。
//
import '../entities/bazi_chart.dart';
import '../entities/bazi_request.dart';

abstract class BaziCalculator {
  Future<BaziChart> calculate(BaziRequest request);
}
