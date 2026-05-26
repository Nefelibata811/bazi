import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:bazi_app/features/history/infrastructure/birth_display_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('农历录入列表文案仅显示农历', () {
    final label = formatBirthLabel(
      BaziRequest(
        calendarType: CalendarType.lunar,
        gender: Gender.male,
        solarDateTime: DateTime(2026, 5, 26, 5, 0),
        lunarYear: 1974,
        lunarMonth: 10,
        lunarDay: 25,
        isLeapMonth: false,
        birthPlaceName: '北京',
        useTrueSolarTime: true,
        longitude: 116.4,
      ),
    );
    expect(label, '农历1974年10月25日 05时');
    expect(label, isNot(contains('公历')));
    expect(label, isNot(contains('北京')));
  });

  test('公历录入列表文案仅显示公历', () {
    final label = formatBirthLabel(
      BaziRequest(
        calendarType: CalendarType.solar,
        gender: Gender.male,
        solarDateTime: DateTime(1990, 8, 15, 14, 20),
        lunarYear: 1990,
        lunarMonth: 8,
        lunarDay: 15,
        isLeapMonth: false,
        birthPlaceName: '上海',
      ),
    );
    expect(label, '1990年8月15日 14:20');
    expect(label, isNot(contains('农历')));
    expect(label, isNot(contains('上海')));
  });
}
