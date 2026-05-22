import 'dart:convert';

import '../../../domain/entities/bazi_report.dart';
import '../../../domain/entities/pillar.dart';
import '../../../domain/value_objects/calendar_type.dart';
import '../../../domain/value_objects/gender.dart';

/// Encodes [BaziReport] to JSON strings stored in `bazi_records`.
class BaziRecordEncoder {
  const BaziRecordEncoder._();

  static String encodeRequest(BaziReport report, String personName) {
    return jsonEncode({
      'calendarType': report.request.calendarType == CalendarType.lunar
          ? 'lunar'
          : 'solar',
      'gender': report.request.gender == Gender.female ? 'female' : 'male',
      'solarDateTime': report.request.solarDateTime.toIso8601String(),
      'lunarYear': report.request.lunarYear,
      'lunarMonth': report.request.lunarMonth,
      'lunarDay': report.request.lunarDay,
      'isLeapMonth': report.request.isLeapMonth,
      'personName': personName.isNotEmpty ? personName : '未命名',
    });
  }

  static String encodeReport(BaziReport report) {
    return jsonEncode({
      'dayMaster': report.chart.dayMaster,
      'year': pillarToJson(report.chart.year),
      'month': pillarToJson(report.chart.month),
      'day': pillarToJson(report.chart.day),
      'hour': pillarToJson(report.chart.hour),
      'analysis': {
        'patterns': report.analysis.patterns
            .map((p) => {
                  'name': p.name,
                  'summary': p.summary,
                  'evidence': p.evidence,
                  'confidence': p.confidence,
                })
            .toList(),
        'shenshaItems': report.analysis.shenshaItems
            .map((s) => {
                  'name': s.name,
                  'target': s.target,
                  'description': s.description,
                  'pillar': s.pillar,
                })
            .toList(),
        'usefulGod': {
          'usefulGod': report.analysis.usefulGod.usefulGod,
          'supportiveGod': report.analysis.usefulGod.supportiveGod,
          'avoidGod': report.analysis.usefulGod.avoidGod,
          'summary': report.analysis.usefulGod.summary,
          'dayMasterStrength': report.analysis.usefulGod.dayMasterStrength,
        },
        'notes': report.analysis.notes,
        'interactions': report.analysis.interactions
            .map((r) => {
                  'type': r.type.name,
                  'nodeA': r.nodeA,
                  'nodeB': r.nodeB,
                  'combinedElement': r.combinedElement,
                  'description': r.description,
                })
            .toList(),
      },
      if (report.boneWeight != null)
        'boneWeight': {
          'totalWeight': report.boneWeight!.totalWeight,
          'maleComment': report.boneWeight!.maleComment,
          'femaleComment': report.boneWeight!.femaleComment,
        },
      if (report.luckCycles.isNotEmpty)
        'luckCycles': report.luckCycles.take(5).map((lc) => {
              'index': lc.index,
              'ganZhi': lc.ganZhi,
              'tenGod': lc.tenGod,
              'startAge': lc.startAge,
              'startYear': lc.startYear,
              'endYear': lc.endYear,
            }).toList(),
    });
  }

  static Map<String, dynamic> pillarToJson(Pillar p) {
    return {
      'stem': p.stem,
      'branch': p.branch,
      'tenGod': p.tenGod,
      'naYin': p.naYin,
      'growthPhase': p.growthPhase,
      'xunKong': p.xunKong,
      'hiddenStems': p.hiddenStems
          .map((h) => {
                'stem': h.stem,
                'tenGod': h.tenGod,
              })
          .toList(),
    };
  }
}
