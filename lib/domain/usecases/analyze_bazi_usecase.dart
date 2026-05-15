import '../entities/analysis_result.dart';
import '../entities/bazi_chart.dart';
import '../services/pattern_analyzer.dart';
import '../services/shensha_calculator.dart';
import '../services/useful_god_analyzer.dart';

class AnalyzeBaziUseCase {
  const AnalyzeBaziUseCase({
    required PatternAnalyzer patternAnalyzer,
    required ShenshaCalculator shenshaCalculator,
    required UsefulGodAnalyzer usefulGodAnalyzer,
  })  : _patternAnalyzer = patternAnalyzer,
        _shenshaCalculator = shenshaCalculator,
        _usefulGodAnalyzer = usefulGodAnalyzer;

  final PatternAnalyzer _patternAnalyzer;
  final ShenshaCalculator _shenshaCalculator;
  final UsefulGodAnalyzer _usefulGodAnalyzer;

  Future<AnalysisResult> call(BaziChart chart) async {
    final patterns = await _patternAnalyzer.analyze(chart);
    final shenshaItems = await _shenshaCalculator.calculate(chart);
    final usefulGod = await _usefulGodAnalyzer.analyze(
      chart: chart,
      patterns: patterns,
    );

    return AnalysisResult(
      patterns: patterns,
      shenshaItems: shenshaItems,
      usefulGod: usefulGod,
      notes: const [
        '当前为领域骨架版本，后续可替换为节气精算、格局法与神煞规则引擎。',
      ],
    );
  }
}
