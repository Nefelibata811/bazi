import 'hidden_stem.dart';

class Pillar {
  const Pillar({
    required this.label,
    required this.stem,
    required this.branch,
    required this.tenGod,
    required this.hiddenStems,
    required this.naYin,
    required this.growthPhase,
    this.xunKong = '',
  });

  final String label;
  final String stem;
  final String branch;
  final String tenGod;
  final List<HiddenStem> hiddenStems;
  final String naYin;
  final String growthPhase;
  final String xunKong;

  String get stemYinYang {
    final code = stem.codeUnitAt(0);
    return code % 2 == 1 ? '阳' : '阴';
  }

  String get branchYinYang {
    final code = branch.codeUnitAt(0);
    return code % 2 == 1 ? '阳' : '阴';
  }

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
