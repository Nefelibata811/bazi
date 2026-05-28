// 文件：四柱
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/four_pillars.dart`。
//
import 'gan_zhi.dart';

/// 类 `FourPillars`：实现 Four Pillars 相关逻辑。
class FourPillars {
  const FourPillars({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
  });

  final GanZhi year;
  final GanZhi month;
  final GanZhi day;
  final GanZhi hour;
}
