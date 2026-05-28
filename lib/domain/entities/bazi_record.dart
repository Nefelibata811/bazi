// 文件：八字记录
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/bazi_record.dart`。
//
import 'dart:convert';

/// 类 `BaziRecord`：实现 Bazi Record 相关逻辑。
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'personName': personName,
        'requestJson': requestJson,
        'reportJson': reportJson,
        'savedAt': savedAt.toIso8601String(),
      };

  factory BaziRecord.fromJson(Map<String, dynamic> json) {
    return BaziRecord(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      personName: json['personName'] as String? ?? '',
      requestJson: json['requestJson'] as String? ?? '',
      reportJson: json['reportJson'] as String? ?? '',
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  String get birthLabel {
    try {
      final req = jsonDecode(requestJson) as Map<String, dynamic>;
      final solar = DateTime.parse(req['solarDateTime'] as String);
      final hour = solar.hour.toString().padLeft(2, '0');
      final minute = solar.minute.toString().padLeft(2, '0');
      final time = minute == '00' ? '$hour时' : '$hour:$minute';
      final base = '${solar.year}年${solar.month}月${solar.day}日 $time';
      final place = req['birthPlaceName'] as String?;
      final useTst = req['useTrueSolarTime'] as bool? ?? false;
      if (useTst && place != null && place.isNotEmpty) {
        return '$base · $place（真太阳时）';
      }
      return base;
    } catch (_) {
      return dateLabel;
    }
  }
}
