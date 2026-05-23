import 'package:bazi_app/domain/entities/bazi_request.dart';
import 'package:bazi_app/domain/value_objects/bazi_sect.dart';
import 'package:bazi_app/domain/value_objects/calendar_type.dart';
import 'package:bazi_app/domain/value_objects/gender.dart';
import 'package:bazi_app/features/history/infrastructure/person_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final request = BaziRequest(
    calendarType: CalendarType.solar,
    gender: Gender.male,
    solarDateTime: DateTime(1990, 8, 15, 14, 20),
    lunarYear: 1990,
    lunarMonth: 7,
    lunarDay: 25,
    isLeapMonth: false,
    baziSect: BaziSect.sameDay,
  );

  test('姓名规范化合并首尾空格', () {
    expect(PersonIdentity.normalizeName('  周云川  '), '周云川');
  });

  test('同名同出生指纹一致', () {
    final a = PersonIdentity.fromSave(personName: '周云川', request: request);
    final b = PersonIdentity.fromSave(personName: ' 周云川 ', request: request);
    expect(a.groupKey, b.groupKey);
  });

  test('同名不同出生指纹不同', () {
    final other = BaziRequest(
      calendarType: CalendarType.solar,
      gender: Gender.male,
      solarDateTime: DateTime(1990, 8, 16, 14, 20),
      lunarYear: 1990,
      lunarMonth: 7,
      lunarDay: 26,
      isLeapMonth: false,
    );
    final a = PersonIdentity.fromSave(personName: '周云川', request: request);
    final b = PersonIdentity.fromSave(personName: '周云川', request: other);
    expect(a.groupKey, isNot(b.groupKey));
  });
}
