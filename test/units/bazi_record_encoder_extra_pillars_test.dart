// 文件：单元测试 — 八字记录编解码辅柱
//
// 验证 八字记录编解码辅柱 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'dart:convert';

import 'package:bazi_app/domain/entities/bazi_chart.dart';
import 'package:bazi_app/domain/entities/pillar.dart';
import 'package:bazi_app/features/history/infrastructure/bazi_record_encoder.dart';
import 'package:bazi_app/features/history/infrastructure/report_json_extra_pillars.dart';
import 'package:flutter_test/flutter_test.dart';

Pillar _stubPillar(String label) => Pillar(
      label: label,
      stem: '甲',
      branch: '子',
      tenGod: '—',
      hiddenStems: const [],
      naYin: '—',
      growthPhase: '—',
    );

void main() {
  test('extraPillarsToJson 输出 label 与干支字段', () {
    final chart = BaziChart(
      dayMaster: '甲',
      year: _stubPillar('年'),
      month: _stubPillar('月'),
      day: _stubPillar('日'),
      hour: _stubPillar('时'),
      extraPillars: const [
        Pillar(
          label: '命宫',
          stem: '己',
          branch: '丑',
          tenGod: '正财',
          naYin: '霹雳火',
          growthPhase: '墓',
          hiddenStems: [],
        ),
      ],
    );

    final encoded = BaziRecordEncoder.extraPillarsToJson(chart);
    expect(encoded.length, 1);
    expect(encoded.first['label'], '命宫');
    expect(encoded.first['stem'], '己');
    expect(encoded.first['branch'], '丑');
    expect(encoded.first['naYin'], '霹雳火');

    final merged = ReportJsonExtraPillars.mergeChartExtraPillars(
      reportJson: '{"dayMaster":"甲"}',
      chart: chart,
    );
    final map = jsonDecode(merged) as Map<String, dynamic>;
    expect((map['extraPillars'] as List).length, 1);
  });

  test('ReportJsonExtraPillars.isEncoded 识别已编码报告', () {
    const encoded =
        '{"extraPillars":[{"label":"命宫","stem":"甲","branch":"子"}]}';
    expect(ReportJsonExtraPillars.isEncoded(encoded), isTrue);
    expect(ReportJsonExtraPillars.isEncoded('{"year":{}}'), isFalse);
  });
}
