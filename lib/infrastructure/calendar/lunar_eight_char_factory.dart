import 'package:lunar/lunar.dart';

import '../../domain/entities/bazi_request.dart';
import 'chart_datetime_resolver.dart';

/// 从 [BaziRequest] 构建 lunar [Lunar] / [EightChar] 并应用晚子时流派。
class LunarEightCharFactory {
  const LunarEightCharFactory._();

  static Lunar lunarFromRequest(BaziRequest request) {
    final chartTime = ChartDateTimeResolver.resolve(request);
    return Solar.fromYmdHms(
      chartTime.year,
      chartTime.month,
      chartTime.day,
      chartTime.hour,
      chartTime.minute,
      0,
    ).getLunar();
  }

  static EightChar eightCharFromRequest(BaziRequest request) {
    final ec = lunarFromRequest(request).getEightChar();
    ec.setSect(request.baziSect.lunarSect);
    return ec;
  }
}
