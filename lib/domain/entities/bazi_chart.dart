// 文件：八字命盘
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/bazi_chart.dart`。
//
import 'pillar.dart';

/// 类 `BaziChart`：实现 Bazi Chart 相关逻辑。
class BaziChart {
  const BaziChart({
    required this.dayMaster,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    this.extraPillars = const [],
  });

  final String dayMaster;
  final Pillar year;
  final Pillar month;
  final Pillar day;
  final Pillar hour;
  /// 命宫、身宫、胎元、胎息
  final List<Pillar> extraPillars;

  List<Pillar> get pillars => [year, month, day, hour];

  List<Pillar> get allPillars => [...pillars, ...extraPillars];
}
