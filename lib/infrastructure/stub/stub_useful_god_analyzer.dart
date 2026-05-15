import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/pattern_result.dart';
import '../../domain/entities/useful_god_result.dart';
import '../../domain/services/useful_god_analyzer.dart';

class StubUsefulGodAnalyzer implements UsefulGodAnalyzer {
  @override
  Future<UsefulGodResult> analyze({
    required BaziChart chart,
    required List<PatternResult> patterns,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final patternName = patterns.isEmpty ? '未定格' : patterns.first.name;

    return UsefulGodResult(
      dayMasterStrength: '日主偏弱',
      usefulGod: '金水',
      supportiveGod: '印比',
      avoidGod: '火土过旺',
      summary: '当前以 $patternName 为参考，先扶日主，再议财官平衡。',
    );
  }
}
