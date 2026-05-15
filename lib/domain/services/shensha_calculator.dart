import '../entities/bazi_chart.dart';
import '../entities/shensha_item.dart';

abstract class ShenshaCalculator {
  Future<List<ShenshaItem>> calculate(BaziChart chart);
}
