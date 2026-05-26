// 八字单柱领域模型：干支、十神、藏干、纳音、星运、自坐等。
// - growthPhase：日主看地支的十二长生（表中「星运」）
// - seatGrowthPhase：天干自坐地支的十二长生（表中「自坐」）
import 'hidden_stem.dart';

/// 年/月/日/时柱或命宫等辅柱的一条记录。
class Pillar {
  const Pillar({
    required this.label,
    required this.stem,
    required this.branch,
    required this.tenGod,
    required this.hiddenStems,
    required this.naYin,
    required this.growthPhase,
    this.seatGrowthPhase = '',
    this.xunKong = '',
  });

  final String label;
  final String stem;
  final String branch;
  final String tenGod;
  final List<HiddenStem> hiddenStems;
  final String naYin;
  /// 日主在该柱地支的十二长生（星运）。
  final String growthPhase;
  /// 天干自坐地支的十二长生。
  final String seatGrowthPhase;
  final String xunKong;

  static const _yangStems = {'甲', '丙', '戊', '庚', '壬'};
  static const _yangBranches = {'子', '寅', '辰', '午', '申', '戌'};

  String get stemYinYang => _yangStems.contains(stem) ? '阳' : '阴';

  String get branchYinYang => _yangBranches.contains(branch) ? '阳' : '阴';

  String get stemFiveElement {
    switch (stem) {
      case '甲': case '乙': return '木';
      case '丙': case '丁': return '火';
      case '戊': case '己': return '土';
      case '庚': case '辛': return '金';
      case '壬': case '癸': return '水';
      default: return '';
    }
  }

  String get branchFiveElement {
    switch (branch) {
      case '寅': case '卯': return '木';
      case '巳': case '午': return '火';
      case '辰': case '戌': case '丑': case '未': return '土';
      case '申': case '酉': return '金';
      case '亥': case '子': return '水';
      default: return '';
    }
  }

  String get stemHint {
    final yinYang = stemYinYang;
    final element = stemFiveElement;
    return '$yinYang$element';
  }

  String get branchHint {
    final yinYang = branchYinYang;
    final element = branchFiveElement;
    return '$yinYang$element';
  }
}
