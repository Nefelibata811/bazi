import 'dart:convert';

import '../../../domain/entities/bazi_chart.dart';
import '../../../domain/services/bazi_calculator.dart';
import 'bazi_record_encoder.dart';
import 'bazi_request_codec.dart';

/// 为缺少辅命宫位的历史 reportJson 按需补全（供 AI 摘要等）。
class ReportJsonExtraPillars {
  const ReportJsonExtraPillars._();

  static bool isEncoded(String reportJson) {
    try {
      final repMap = jsonDecode(reportJson) as Map<String, dynamic>;
      final raw = repMap['extraPillars'];
      return raw is List && raw.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<String> ensureEncoded({
    required String requestJson,
    required String reportJson,
    required BaziCalculator calculator,
  }) async {
    if (isEncoded(reportJson)) return reportJson;

    final request = BaziRequestCodec.fromJson(requestJson);
    if (request == null) return reportJson;

    try {
      final chart = await calculator.calculate(request);
      return mergeChartExtraPillars(reportJson: reportJson, chart: chart);
    } catch (_) {
      return reportJson;
    }
  }

  static String mergeChartExtraPillars({
    required String reportJson,
    required BaziChart chart,
  }) {
    if (chart.extraPillars.isEmpty) return reportJson;

    try {
      final repMap = jsonDecode(reportJson) as Map<String, dynamic>;
      repMap['extraPillars'] = BaziRecordEncoder.extraPillarsToJson(chart);
      return jsonEncode(repMap);
    } catch (_) {
      return reportJson;
    }
  }
}
