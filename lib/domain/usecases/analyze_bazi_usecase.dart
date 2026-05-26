import '../entities/analysis_result.dart';
import '../entities/bazi_chart.dart';
import '../services/pattern_analyzer.dart';
import '../services/shensha_calculator.dart';
import '../services/useful_god_analyzer.dart';
import '../../infrastructure/calendar/interaction_calculator.dart';

class AnalyzeBaziUseCase {
  const AnalyzeBaziUseCase({
    required PatternAnalyzer patternAnalyzer,
    required ShenshaCalculator shenshaCalculator,
    required UsefulGodAnalyzer usefulGodAnalyzer,
    BaziInteractionCalculator? interactionCalculator,
  })  : _patternAnalyzer = patternAnalyzer,
        _shenshaCalculator = shenshaCalculator,
        _usefulGodAnalyzer = usefulGodAnalyzer,
        _interactionCalculator =
            interactionCalculator ?? const BaziInteractionCalculator();

  final PatternAnalyzer _patternAnalyzer;
  final ShenshaCalculator _shenshaCalculator;
  final UsefulGodAnalyzer _usefulGodAnalyzer;
  final BaziInteractionCalculator _interactionCalculator;

  Future<AnalysisResult> call(BaziChart chart) async {
    final patterns = await _patternAnalyzer.analyze(chart);
    final shenshaItems = await _shenshaCalculator.calculate(chart);
    final pillarInteractions = _interactionCalculator.calculate(chart);
    final hiddenStemInteractions =
        _interactionCalculator.calculateHiddenStemInteractions(chart);
    final interactions = [...pillarInteractions, ...hiddenStemInteractions];
    final usefulGod = await _usefulGodAnalyzer.analyze(
      chart: chart,
      patterns: patterns,
    );

    return AnalysisResult(
      patterns: patterns,
      shenshaItems: shenshaItems,
      usefulGod: usefulGod,
      interactions: interactions,
      notes: const [],
    );
  }
}
