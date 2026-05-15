import '../entities/bazi_chart.dart';
import '../entities/bazi_request.dart';
import '../services/bazi_calculator.dart';

class BuildBaziChartUseCase {
  const BuildBaziChartUseCase(this._calculator);

  final BaziCalculator _calculator;

  Future<BaziChart> call(BaziRequest request) {
    return _calculator.calculate(request);
  }
}
