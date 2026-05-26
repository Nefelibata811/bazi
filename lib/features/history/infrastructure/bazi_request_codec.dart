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
      'useTrueSolarTime': request.useTrueSolarTime,
      if (request.longitude != null) 'longitude': request.longitude,
      if (request.latitude != null) 'latitude': request.latitude,
      if (request.birthPlaceName != null) 'birthPlaceName': request.birthPlaceName,
      'standardMeridian': request.standardMeridian,
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
        useTrueSolarTime: map['useTrueSolarTime'] as bool? ?? false,
        longitude: (map['longitude'] as num?)?.toDouble(),
        latitude: (map['latitude'] as num?)?.toDouble(),
        birthPlaceName: map['birthPlaceName'] as String?,
        standardMeridian:
            (map['standardMeridian'] as num?)?.toDouble() ?? 120.0,
      );
    } catch (_) {
      return null;
    }
  }
}
