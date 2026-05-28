// 文件：历法转换
//
// 路径：`lib/domain/services/calendar_converter.dart`。
//
import '../entities/bazi_request.dart';
import '../entities/calendar_snapshot.dart';

abstract class CalendarConverter {
  Future<CalendarSnapshot> resolve(BaziRequest request);
}
