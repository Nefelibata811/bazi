// 文件：analysis结果
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/analysis_result.dart`。
//
import 'interaction_result.dart';
import 'pattern_result.dart';
import 'shensha_item.dart';
import 'useful_god_result.dart';

/// 类 `AnalysisResult`：实现 Analysis Result 相关逻辑。
class AnalysisResult {
  const AnalysisResult({
    required this.patterns,
    required this.shenshaItems,
    required this.usefulGod,
    required this.notes,
    this.interactions = const [],
  });

  final List<PatternResult> patterns;
  final List<ShenshaItem> shenshaItems;
  final UsefulGodResult usefulGod;
  final List<String> notes;
  final List<InteractionResult> interactions;
}
