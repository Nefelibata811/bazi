/// 流年下的流月干支（五虎遁月）。
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
