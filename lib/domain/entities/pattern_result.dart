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
