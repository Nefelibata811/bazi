// 文件：八字sect
//
// 路径：`lib/domain/value_objects/bazi_sect.dart`。
//
enum BaziSect {
  /// sect=2：23:00–24:00 晚子时日柱仍按当天（lunar 默认）
  sameDay(2, '晚子按当天'),

  /// sect=1：晚子时日柱按次日
  nextDay(1, '晚子按次日');

  const BaziSect(this.lunarSect, this.label);

  final int lunarSect;
  final String label;

  static BaziSect fromJson(String? value) {
    return value == 'nextDay' ? BaziSect.nextDay : BaziSect.sameDay;
  }

  String toJson() => name;
}

bool isZiHour(int hour) => hour == 23 || hour == 0;
