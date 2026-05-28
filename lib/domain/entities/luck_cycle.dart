// 文件：大运运程
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/luck_cycle.dart`。
//
import 'flowing_year.dart';

/// 类 `LuckCycle`：实现 Luck Cycle 相关逻辑。
class LuckCycle {
  const LuckCycle({
    required this.index,
    required this.ganZhi,
    required this.tenGod,
    required this.startYear,
    required this.endYear,
    required this.startAge,
    required this.endAge,
    required this.flowingYears,
    this.isPreStart = false,
  });

  final int index;
  final String ganZhi;
  final String tenGod;
  final int startYear;
  final int endYear;
  final int startAge;
  final int endAge;
  final List<FlowingYear> flowingYears;
  /// index=0：出生至交大运前（流年 + 小运）
  final bool isPreStart;
}
