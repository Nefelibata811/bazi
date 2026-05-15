import 'pattern_result.dart';
import 'shensha_item.dart';
import 'useful_god_result.dart';

class AnalysisResult {
  const AnalysisResult({
    required this.patterns,
    required this.shenshaItems,
    required this.usefulGod,
    required this.notes,
  });

  final List<PatternResult> patterns;
  final List<ShenshaItem> shenshaItems;
  final UsefulGodResult usefulGod;
  final List<String> notes;
}
