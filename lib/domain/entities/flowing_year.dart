// 文件：flowingyear
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/flowing_year.dart`。
//
import 'flowing_month.dart';

/// 类 `FlowingYear`：实现 Flowing Year 相关逻辑。
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
