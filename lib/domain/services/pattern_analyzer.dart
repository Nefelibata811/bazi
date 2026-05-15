import '../entities/bazi_chart.dart';
import '../entities/pattern_result.dart';

abstract class PatternAnalyzer {
  Future<List<PatternResult>> analyze(BaziChart chart);
}
