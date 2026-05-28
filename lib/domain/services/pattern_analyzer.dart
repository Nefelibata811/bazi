// 文件：格局analyzer
//
// 路径：`lib/domain/services/pattern_analyzer.dart`。
//
import '../entities/bazi_chart.dart';
import '../entities/pattern_result.dart';

abstract class PatternAnalyzer {
  Future<List<PatternResult>> analyze(BaziChart chart);
}
