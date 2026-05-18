class JulianDay {
  const JulianDay._();

  // 公历转儒略日（整数），适用于 1900-2100 年，用于干支推算日柱。
  static int fromDateTime(DateTime dt) {
    var y = dt.year;
    var m = dt.month;
    final d = dt.day;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }

    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4;

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524;
  }

  // 公历转儒略日（浮点带时分秒），用于天文节气精算。
  static double fromDateTimeExact(DateTime dt) {
    final jd = fromDateTime(dt).toDouble();
    final frac = (dt.hour * 3600 + dt.minute * 60 + dt.second) / 86400.0;
    return jd + frac;
  }

  // 儒略日反算公历日期（整数日）。
  static DateTime toDateTime(int jd) {
    var z = jd;
    final a = ((z - 1867216.25) / 36524.25).floor();
    final b = z + 1 + a - (a ~/ 4);
    final c = b + 1524;
    final e = ((c.toDouble() - 122.1) / 365.25).floor();
    final f = (365.25 * e).floor();
    final g = ((c.toDouble() - f) / 30.6001).floor();

    final day = (c - f - (30.6001 * g).floor()).toInt();
    var month = g - 1;
    if (g > 13) month = g - 13;
    var year = e;
    if (month > 2) {
      year -= 4716;
    } else {
      year -= 4715;
    }

    return DateTime(year, month, day);
  }

  // 儒略日（浮点）反算公历 DateTime，精确到秒。
  static DateTime toDateTimeExact(double jd) {
    final intPart = jd.floor();
    final fracDay = jd - intPart;
    final baseDate = toDateTime(intPart);

    final totalSeconds = (fracDay * 86400).round();
    final hour = totalSeconds ~/ 3600;
    final minute = (totalSeconds % 3600) ~/ 60;
    final second = totalSeconds % 60;

    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
      second,
    );
  }
}
