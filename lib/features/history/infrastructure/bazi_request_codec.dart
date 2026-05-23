import 'dart:convert';

import '../../../domain/entities/bazi_request.dart';
import '../../../domain/value_objects/bazi_sect.dart';
import '../../../domain/value_objects/calendar_type.dart';
import '../../../domain/value_objects/gender.dart';

class BaziRequestCodec {
  const BaziRequestCodec._();

  static Map<String, dynamic> toJson(BaziRequest request, {String? personName}) {
    return {
      'calendarType':
          request.calendarType == CalendarType.lunar ? 'lunar' : 'solar',
      'gender': request.gender == Gender.female ? 'female' : 'male',
      'solarDateTime': request.solarDateTime.toIso8601String(),
      'lunarYear': request.lunarYear,
      'lunarMonth': request.lunarMonth,
      'lunarDay': request.lunarDay,
      'isLeapMonth': request.isLeapMonth,
      'baziSect': request.baziSect.toJson(),
      if (personName != null) 'personName': personName,
    };
  }

  static BaziRequest? fromJson(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return BaziRequest(
        calendarType: map['calendarType'] == 'lunar'
            ? CalendarType.lunar
            : CalendarType.solar,
        gender: map['gender'] == 'female' ? Gender.female : Gender.male,
        solarDateTime: DateTime.parse(map['solarDateTime'] as String),
        lunarYear: map['lunarYear'] as int,
        lunarMonth: map['lunarMonth'] as int,
        lunarDay: map['lunarDay'] as int,
        isLeapMonth: map['isLeapMonth'] as bool? ?? false,
        baziSect: BaziSect.fromJson(map['baziSect'] as String?),
        personName: map['personName'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
