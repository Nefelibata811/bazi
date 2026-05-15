class BaziRecord {
  const BaziRecord({
    required this.id,
    required this.userId,
    required this.personName,
    required this.requestJson,
    required this.reportJson,
    required this.savedAt,
  });

  final String id;
  final String userId;
  final String personName;
  final String requestJson;
  final String reportJson;
  final DateTime savedAt;

  String get dateLabel {
    return '${savedAt.year}年${savedAt.month}月${savedAt.day}日';
  }
}
