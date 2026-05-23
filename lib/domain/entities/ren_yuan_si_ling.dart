/// 月令人元司令（司事之神）。
class RenYuanSiLing {
  const RenYuanSiLing({
    required this.stem,
    required this.origin,
    required this.daysSinceJie,
    required this.monthBranch,
  });

  final String stem;
  final String origin;
  final double daysSinceJie;
  final String monthBranch;

  String get summary => '$origin（$stem）司令 · 距节${daysSinceJie.toStringAsFixed(1)}天';
}
