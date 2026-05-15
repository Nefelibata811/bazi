class SolarTermInfo {
  const SolarTermInfo({
    required this.name,
    required this.occurredAt,
    required this.index,
    this.termMonth,
  });

  final String name;
  final DateTime occurredAt;

  // 节气序号：小寒=0, 大寒=1, 立春=2, ..., 冬至=23
  final int index;

  // 该节气所属的月支序（寅月=0, 卯月=1, ..., 丑月=11），仅节类节气有值
  final int? termMonth;
}
