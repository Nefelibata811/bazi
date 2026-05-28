// 文件：格局结果
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/pattern_result.dart`。
//
class PatternResult {
  const PatternResult({
    required this.name,
    required this.summary,
    required this.evidence,
    this.confidence = 0.0,
  });

  final String name;
  final String summary;
  final List<String> evidence;
  final double confidence;
}
