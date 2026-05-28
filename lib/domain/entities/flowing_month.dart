// 文件：flowingmonth
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/flowing_month.dart`。
//
class FlowingMonth {
  const FlowingMonth({
    required this.index,
    required this.monthName,
    required this.ganZhi,
    required this.tenGod,
  });

  /// 1–12，正月为 1
  final int index;
  final String monthName;
  final String ganZhi;
  final String tenGod;
}
