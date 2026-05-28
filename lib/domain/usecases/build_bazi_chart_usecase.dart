// 文件：build八字命盘用例
//
// 路径：`lib/domain/usecases/build_bazi_chart_usecase.dart`。
//
import '../entities/bazi_chart.dart';
import '../entities/bazi_request.dart';
import '../services/bazi_calculator.dart';

/// 类 `BuildBaziChartUseCase`：实现 Build Bazi Chart Use Case 相关逻辑。
class BuildBaziChartUseCase {
  const BuildBaziChartUseCase(this._calculator);

  final BaziCalculator _calculator;

  Future<BaziChart> call(BaziRequest request) {
    return _calculator.calculate(request);
  }
}
