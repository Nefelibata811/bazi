class JulianDay {
  const JulianDay._();

  /// 公历转儒略日（整数，日历日正午 JD 的整数部分，用于干支日柱）。
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

  /// 浮点儒略日（0 点为 JD - 0.5）。
  static double fromDateTimeExact(DateTime dt) {
    final dayJd = fromDateTime(dt);
    final frac =
        (dt.hour * 3600 + dt.minute * 60 + dt.second) / 86400.0;
    return dayJd - 0.5 + frac;
  }

  static DateTime toDateTime(int jd) => _calendarFromZ(jd);

  static DateTime toDateTimeExact(double jd) {
    final z = (jd + 0.5).floor();
    final fracDay = jd + 0.5 - z;
    final baseDate = _calendarFromZ(z);

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

  static DateTime _calendarFromZ(int z) {
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
}
