// 文件：人元元司ling
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/ren_yuan_si_ling.dart`。
//
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
