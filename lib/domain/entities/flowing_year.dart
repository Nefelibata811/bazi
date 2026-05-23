import 'flowing_month.dart';

class FlowingYear {
  const FlowingYear({
    required this.year,
    required this.ganZhi,
    required this.tenGod,
    this.xiaoYunGanZhi,
    this.flowingMonths = const [],
  });

  final int year;
  /// 流年干支
  final String ganZhi;
  final String tenGod;
  /// 起运前各年小运干支（仅 [LuckCycle.isPreStart] 时有值）
  final String? xiaoYunGanZhi;
  final List<FlowingMonth> flowingMonths;
}
