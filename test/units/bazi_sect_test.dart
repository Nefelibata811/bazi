import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/value_objects/bazi_sect.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:bazi_app/infrastructure/calendar/lunar_eight_char_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('晚子按次日与日柱不同于按当天', () {
    final base = BaziRequest(
      calendarType: CalendarType.solar,
      gender: Gender.male,
      solarDateTime: DateTime(2024, 1, 1, 23, 30),
      lunarYear: 2024,
      lunarMonth: 1,
      lunarDay: 1,
      isLeapMonth: false,
    );
    final sameDay = LunarEightCharFactory.eightCharFromRequest(
      BaziRequest(
        calendarType: base.calendarType,
        gender: base.gender,
        solarDateTime: base.solarDateTime,
        lunarYear: base.lunarYear,
        lunarMonth: base.lunarMonth,
        lunarDay: base.lunarDay,
        isLeapMonth: base.isLeapMonth,
        baziSect: BaziSect.sameDay,
      ),
    );
    final nextDay = LunarEightCharFactory.eightCharFromRequest(
      BaziRequest(
        calendarType: base.calendarType,
        gender: base.gender,
        solarDateTime: base.solarDateTime,
        lunarYear: base.lunarYear,
        lunarMonth: base.lunarMonth,
        lunarDay: base.lunarDay,
        isLeapMonth: base.isLeapMonth,
        baziSect: BaziSect.nextDay,
      ),
    );
    expect(sameDay.getDay(), isNot(nextDay.getDay()));
  });
}
