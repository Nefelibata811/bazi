import '../../../domain/entities/bazi_request.dart';
import '../../../domain/value_objects/calendar_type.dart';
import '../../../infrastructure/calendar/chart_datetime_resolver.dart';
import 'bazi_request_codec.dart';

/// 列表/选盘等紧凑展示：按录入历法只显示一种，不含出生地。
List<String> birthDisplayLines(BaziRequest request) {
  final clock = ChartDateTimeResolver.clockLocal(request);
  final hour = clock.hour.toString().padLeft(2, '0');
  final minute = clock.minute.toString().padLeft(2, '0');
  final time = clock.minute == 0 ? '$hour时' : '$hour:$minute';

  if (request.calendarType == CalendarType.lunar) {
    final leap = request.isLeapMonth ? '闰' : '';
    return [
      '农历${request.lunarYear}年$leap${request.lunarMonth}月${request.lunarDay}日 $time',
    ];
  }
  return ['${clock.year}年${clock.month}月${clock.day}日 $time'];
}

/// 命主列表、选盘等展示的出生时间文案（多行时用换行连接）。
String formatBirthLabel(BaziRequest request) =>
    birthDisplayLines(request).join('\n');

List<String>? birthDisplayLinesFromRequestJson(String requestJson) {
  try {
    final request = BaziRequestCodec.fromJson(requestJson);
    if (request == null) return null;
    return birthDisplayLines(request);
  } catch (_) {
    return null;
  }
}

String? formatBirthLabelFromRequestJson(String requestJson) {
  try {
    final request = BaziRequestCodec.fromJson(requestJson);
    if (request == null) return null;
    return formatBirthLabel(request);
  } catch (_) {
    return null;
  }
}
