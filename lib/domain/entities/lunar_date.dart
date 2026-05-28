// 文件：农历date
//
// 领域实体：承载业务数据字段。
// 路径：`lib/domain/entities/lunar_date.dart`。
//
class LunarDate {
  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
  });

  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;
}
