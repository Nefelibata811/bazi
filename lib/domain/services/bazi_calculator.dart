import '../entities/bazi_chart.dart';
import '../entities/bazi_request.dart';

abstract class BaziCalculator {
  Future<BaziChart> calculate(BaziRequest request);
}
