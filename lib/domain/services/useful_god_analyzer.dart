// 文件：用神godanalyzer
//
// 路径：`lib/domain/services/useful_god_analyzer.dart`。
//
import '../entities/bazi_chart.dart';
import '../entities/pattern_result.dart';
import '../entities/useful_god_result.dart';

abstract class UsefulGodAnalyzer {
  Future<UsefulGodResult> analyze({
    required BaziChart chart,
    required List<PatternResult> patterns,
  });
}
