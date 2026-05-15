class SavedChart {
  const SavedChart({
    required this.id,
    required this.userId,
    required this.title,
    required this.requestJson,
    required this.reportJson,
    required this.savedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String requestJson;
  final String reportJson;
  final DateTime savedAt;
}
