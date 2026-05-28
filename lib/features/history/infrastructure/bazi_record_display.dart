// 文件：八字记录展示
//
// 路径：`lib/features/history/infrastructure/bazi_record_display.dart`。
//
import '../../../domain/entities/bazi_record.dart';
import 'birth_display_label.dart';

/// 扩展 `BaziRecordDisplay`：为类型增加 Bazi Record Display 方法。
extension BaziRecordDisplay on BaziRecord {
  /// 列表/选盘展示用出生时间（农历按农历+公历，不读未同步的 solarDateTime 年月日）。
  String get displayBirthLabel =>
      formatBirthLabelFromRequestJson(requestJson) ?? birthLabel;
}
