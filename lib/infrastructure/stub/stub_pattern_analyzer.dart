import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/pattern_result.dart';
import '../../domain/services/pattern_analyzer.dart';

class StubPatternAnalyzer implements PatternAnalyzer {
  @override
  Future<List<PatternResult>> analyze(BaziChart chart) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));

    return [
      PatternResult(
        name: '偏财格取象',
        summary: '以月干透财为切入点，先立财星格意，再看官印是否成辅。',
        evidence: [
          '月柱透丙，财星外显。',
          '日主癸水坐未，财官食同宫，宜结合扶抑再定高低。',
        ],
        confidence: 0.62,
      ),
    ];
  }
}
