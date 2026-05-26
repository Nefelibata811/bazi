import '../../../domain/entities/bazi_record.dart';
import '../../../domain/entities/bazi_request.dart';
import '../../../domain/value_objects/calendar_type.dart';
import 'bazi_request_codec.dart';

/// 命主唯一标识：规范化姓名 + 出生时刻指纹（同名不同人可区分）。
class PersonIdentity {
  const PersonIdentity({
    required this.displayName,
    required this.birthFingerprint,
  });

  final String displayName;
  final String birthFingerprint;

  String get groupKey => '$displayName|$birthFingerprint';

  static String normalizeName(String name) {
    final trimmed = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    return trimmed.isEmpty ? '未命名' : trimmed;
  }

  static String birthFingerprintFromRequest(BaziRequest request) {
    final dt = request.solarDateTime;
    final base =
        '${request.calendarType.name}|${request.gender.name}|${request.baziSect.name}|'
        '${dt.year}-${dt.month}-${dt.day}-${dt.hour}-${dt.minute}';
    final location = request.useTrueSolarTime && request.longitude != null
        ? '|tst:${request.longitude!.toStringAsFixed(4)}'
        : '';
    if (request.calendarType == CalendarType.lunar) {
      return '$base|l:${request.lunarYear}-${request.lunarMonth}-'
          '${request.lunarDay}-${request.isLeapMonth}$location';
    }
    return '$base$location';
  }

  static String birthFingerprintFromRequestJson(String requestJson) {
    try {
      final request = BaziRequestCodec.fromJson(requestJson);
      if (request == null) {
        return requestJson.hashCode.toString();
      }
      return birthFingerprintFromRequest(request);
    } catch (_) {
      return requestJson.hashCode.toString();
    }
  }

  static PersonIdentity fromRecord(BaziRecord record) {
    return PersonIdentity(
      displayName: normalizeName(record.personName),
      birthFingerprint: birthFingerprintFromRequestJson(record.requestJson),
    );
  }

  static PersonIdentity fromSave({
    required String personName,
    required BaziRequest request,
  }) {
    return PersonIdentity(
      displayName: normalizeName(personName),
      birthFingerprint: birthFingerprintFromRequest(request),
    );
  }

  /// 同一命主（姓名+出生）只保留最近保存的一条。
  static List<BaziRecord> dedupeRecords(List<BaziRecord> records) {
    final byKey = <String, BaziRecord>{};
    for (final r in records) {
      final key = fromRecord(r).groupKey;
      final existing = byKey[key];
      if (existing == null || r.savedAt.isAfter(existing.savedAt)) {
        byKey[key] = r;
      }
    }
    final result = byKey.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return result;
  }
}
