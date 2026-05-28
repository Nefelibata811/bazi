// 文件：八字报告
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/bazi_report.dart`。
//
import 'analysis_result.dart';
import 'bazi_chart.dart';
import 'bazi_request.dart';
import 'calendar_snapshot.dart';
import 'luck_cycle.dart';
import 'ren_yuan_si_ling.dart';
import 'solar_term_info.dart';

/// 类 `BoneWeight`：实现 Bone Weight 相关逻辑。
class BoneWeight {
  const BoneWeight({
    required this.totalWeight,
    required this.maleComment,
    required this.femaleComment,
  });

  final double totalWeight;
  final String maleComment;
  final String femaleComment;

  String commentFor(bool isMale) => isMale ? maleComment : femaleComment;

  String get weightLabel {
    final liang = totalWeight.floor();
    final qian = ((totalWeight - liang) * 10).round();
    if (qian == 0) return '$liang两';
    return '$liang两$qian钱';
  }
}

/// 类 `BaziReport`：实现 Bazi Report 相关逻辑。
class BaziReport {
  const BaziReport({
    required this.request,
    required this.calendarSnapshot,
    required this.chart,
    required this.solarTerms,
    required this.luckCycles,
    required this.analysis,
    this.boneWeight,
    this.renYuanSiLing,
  });

  final BaziRequest request;
  final CalendarSnapshot calendarSnapshot;
  final BaziChart chart;
  final List<SolarTermInfo> solarTerms;
  final List<LuckCycle> luckCycles;
  final AnalysisResult analysis;
  final BoneWeight? boneWeight;
  final RenYuanSiLing? renYuanSiLing;
}
