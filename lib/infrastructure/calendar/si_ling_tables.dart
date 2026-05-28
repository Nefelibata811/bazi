// 文件：司lingtables
//
// 历法算法：八字排盘核心计算。
// 路径：`lib/infrastructure/calendar/si_ling_tables.dart`。
//
import '../../domain/value_objects/si_ling_version.dart';

/// 人元司令分野天数表（月支 → 司令段列表）。
class SiLingSegment {
  const SiLingSegment(this.stem, this.days, this.origin);

  final String stem;
  final int days;
  final String origin;
}

/// 类 `SiLingTables`：实现 Si Ling Tables 相关逻辑。
class SiLingTables {
  const SiLingTables._();

  static const branches = '子丑寅卯辰巳午未申酉戌亥';

  static const sanMing = <String, List<SiLingSegment>>{
    '寅': [
      SiLingSegment('戊', 5, '艮土'),
      SiLingSegment('丙', 5, '丙火'),
      SiLingSegment('甲', 20, '甲木'),
    ],
    '卯': [
      SiLingSegment('甲', 7, '甲木'),
      SiLingSegment('乙', 23, '乙木'),
    ],
    '辰': [
      SiLingSegment('乙', 7, '乙木'),
      SiLingSegment('壬', 5, '壬水'),
      SiLingSegment('戊', 18, '戊土'),
    ],
    '巳': [
      SiLingSegment('戊', 7, '戊土'),
      SiLingSegment('庚', 5, '庚金'),
      SiLingSegment('丙', 18, '丙火'),
    ],
    '午': [
      SiLingSegment('丙', 7, '丙火'),
      SiLingSegment('丁', 23, '丁火'),
    ],
    '未': [
      SiLingSegment('丁', 7, '丁火'),
      SiLingSegment('甲', 5, '甲木'),
      SiLingSegment('己', 18, '己土'),
    ],
    '申': [
      SiLingSegment('戊', 5, '坤土'),
      SiLingSegment('壬', 5, '壬水'),
      SiLingSegment('庚', 20, '庚金'),
    ],
    '酉': [
      SiLingSegment('庚', 7, '庚金'),
      SiLingSegment('辛', 23, '辛金'),
    ],
    '戌': [
      SiLingSegment('辛', 7, '辛金'),
      SiLingSegment('丙', 5, '丙火'),
      SiLingSegment('戊', 18, '戊土'),
    ],
    '亥': [
      SiLingSegment('戊', 5, '戊土'),
      SiLingSegment('甲', 5, '甲木'),
      SiLingSegment('壬', 20, '壬水'),
    ],
    '子': [
      SiLingSegment('壬', 7, '壬水'),
      SiLingSegment('癸', 23, '癸水'),
    ],
    '丑': [
      SiLingSegment('癸', 7, '癸水'),
      SiLingSegment('庚', 5, '庚金'),
      SiLingSegment('己', 18, '己土'),
    ],
  };

  static const common = <String, List<SiLingSegment>>{
    '寅': [
      SiLingSegment('戊', 7, '戊土'),
      SiLingSegment('丙', 7, '丙火'),
      SiLingSegment('甲', 16, '甲木'),
    ],
    '卯': [
      SiLingSegment('甲', 10, '甲木'),
      SiLingSegment('乙', 20, '乙木'),
    ],
    '辰': [
      SiLingSegment('乙', 9, '乙木'),
      SiLingSegment('癸', 3, '癸水'),
      SiLingSegment('戊', 18, '戊土'),
    ],
    '巳': [
      SiLingSegment('戊', 5, '戊土'),
      SiLingSegment('庚', 9, '庚金'),
      SiLingSegment('丙', 16, '丙火'),
    ],
    '午': [
      SiLingSegment('丙', 10, '丙火'),
      SiLingSegment('己', 9, '己土'),
      SiLingSegment('丁', 11, '丁火'),
    ],
    '未': [
      SiLingSegment('丁', 9, '丁火'),
      SiLingSegment('乙', 3, '乙木'),
      SiLingSegment('己', 18, '己土'),
    ],
    '申': [
      SiLingSegment('戊', 10, '戊土'),
      SiLingSegment('壬', 3, '壬水'),
      SiLingSegment('庚', 17, '庚金'),
    ],
    '酉': [
      SiLingSegment('庚', 10, '庚金'),
      SiLingSegment('辛', 20, '辛金'),
    ],
    '戌': [
      SiLingSegment('辛', 9, '辛金'),
      SiLingSegment('丁', 3, '丁火'),
      SiLingSegment('戊', 18, '戊土'),
    ],
    '亥': [
      SiLingSegment('戊', 7, '戊土'),
      SiLingSegment('甲', 5, '甲木'),
      SiLingSegment('壬', 18, '壬水'),
    ],
    '子': [
      SiLingSegment('壬', 10, '壬水'),
      SiLingSegment('癸', 20, '癸水'),
    ],
    '丑': [
      SiLingSegment('癸', 9, '癸水'),
      SiLingSegment('辛', 3, '辛金'),
      SiLingSegment('己', 18, '己土'),
    ],
  };

  static Map<String, List<SiLingSegment>> tableFor(SiLingVersion version) {
    switch (version) {
      case SiLingVersion.sanMingTongHui:
        return sanMing;
      case SiLingVersion.common:
        return common;
    }
  }
}
