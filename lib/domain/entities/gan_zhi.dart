class GanZhi {
  const GanZhi({
    required this.stem,
    required this.branch,
  });

  final String stem;
  final String branch;

  String get name => '$stem$branch';
}
