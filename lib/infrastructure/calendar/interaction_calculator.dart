import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/interaction_result.dart';
import '../../domain/entities/pillar.dart';

class BaziInteractionCalculator {
  const BaziInteractionCalculator();

  static const _stemCombine = {
    '甲己': '土', '己甲': '土',
    '乙庚': '金', '庚乙': '金',
    '丙辛': '水', '辛丙': '水',
    '丁壬': '木', '壬丁': '木',
    '戊癸': '火', '癸戊': '火',
  };

  static const _branchCombine6 = {
    '子丑': '土', '丑子': '土',
    '寅亥': '木', '亥寅': '木',
    '卯戌': '火', '戌卯': '火',
    '辰酉': '金', '酉辰': '金',
    '巳申': '水', '申巳': '水',
    '午未': '土', '未午': '土',
  };

  static const _branchClash = {
    '子午', '午子', '丑未', '未丑',
    '寅申', '申寅', '卯酉', '酉卯',
    '辰戌', '戌辰', '巳亥', '亥巳',
  };

  static const _branchCombine3Groups = <({List<String> branches, String element})>[
    (branches: ['申', '子', '辰'], element: '水'),
    (branches: ['亥', '卯', '未'], element: '木'),
    (branches: ['寅', '午', '戌'], element: '火'),
    (branches: ['巳', '酉', '丑'], element: '金'),
  ];

  static const _branchHarm = {
    '子未': '子未相害，水被土克',
    '未子': '子未相害，水被土克',
    '丑午': '丑午相害，火生土耗',
    '午丑': '丑午相害，火生土耗',
    '寅巳': '寅巳相害，木生火泄',
    '巳寅': '寅巳相害，木生火泄',
    '卯辰': '卯辰相害，木克土',
    '辰卯': '卯辰相害，木克土',
    '申亥': '申亥相害，金生水泄',
    '亥申': '申亥相害，金生水泄',
    '酉戌': '酉戌相害，金被火克',
    '戌酉': '酉戌相害，金被火克',
  };

  List<InteractionResult> calculate(BaziChart chart) {
    final results = <InteractionResult>[];
    final pillars = chart.pillars;

    _checkStemCombine(results, pillars);
    _checkStemClash(results, pillars);
    _checkBranchCombine6(results, pillars);
    _checkBranchCombine3(results, pillars);
    _checkBranchCombineHalf(results, pillars);
    _checkBranchClash(results, pillars);
    _checkBranchHarm(results, pillars);
    _checkBranchPunish(results, pillars);

    return results;
  }

  void _checkStemCombine(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final pair = '${pillars[i].stem}${pillars[j].stem}';
        final element = _stemCombine[pair];
        if (element != null) {
          results.add(InteractionResult(
            type: InteractionType.stemCombine,
            nodeA: '${pillars[i].label}干${pillars[i].stem}',
            nodeB: '${pillars[j].label}干${pillars[j].stem}',
            combinedElement: element,
            description: '${pillars[i].stem}${pillars[j].stem}合化$element',
          ));
        }
      }
    }
  }

  void _checkStemClash(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final pair = '${pillars[i].stem}${pillars[j].stem}';
        if (_isStemClash(pillars[i].stem, pillars[j].stem)) {
          results.add(InteractionResult(
            type: InteractionType.stemClash,
            nodeA: '${pillars[i].label}干${pillars[i].stem}',
            nodeB: '${pillars[j].label}干${pillars[j].stem}',
            description: '$pair天干相冲',
          ));
        }
      }
    }
  }

  bool _isStemClash(String a, String b) {
    const map = {
      '甲': '庚', '庚': '甲',
      '乙': '辛', '辛': '乙',
      '丙': '壬', '壬': '丙',
      '丁': '癸', '癸': '丁',
    };
    return map[a] == b;
  }

  void _checkBranchCombine6(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final pair = '${pillars[i].branch}${pillars[j].branch}';
        final element = _branchCombine6[pair];
        if (element != null) {
          results.add(InteractionResult(
            type: InteractionType.branchCombine6,
            nodeA: '${pillars[i].label}支${pillars[i].branch}',
            nodeB: '${pillars[j].label}支${pillars[j].branch}',
            combinedElement: element,
            description: '$pair六合化$element',
          ));
        }
      }
    }
  }

  void _checkBranchCombine3(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (final group in _branchCombine3Groups) {
      final hits =
          pillars.where((p) => group.branches.contains(p.branch)).toList();
      final branchSet = hits.map((p) => p.branch).toSet();
      if (branchSet.length != 3 ||
          !group.branches.every(branchSet.contains)) {
        continue;
      }
      final nodes = hits.map((p) => '${p.label}支${p.branch}').join('、');
      results.add(InteractionResult(
        type: InteractionType.branchCombine3,
        nodeA: '${hits[0].label}支${hits[0].branch}',
        nodeB: '${hits[1].label}支${hits[1].branch}',
        combinedElement: group.element,
        description:
            '${group.branches.join('')}三合${group.element}局（$nodes）',
      ));
    }
  }

  void _checkBranchCombineHalf(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (final group in _branchCombine3Groups) {
      final hits =
          pillars.where((p) => group.branches.contains(p.branch)).toList();
      final branchSet = hits.map((p) => p.branch).toSet();
      if (branchSet.length == 3) continue;

      for (var i = 0; i < hits.length; i++) {
        for (var j = i + 1; j < hits.length; j++) {
          final a = hits[i];
          final b = hits[j];
          if (a.branch == b.branch) continue;
          results.add(InteractionResult(
            type: InteractionType.branchCombineHalf,
            nodeA: '${a.label}支${a.branch}',
            nodeB: '${b.label}支${b.branch}',
            combinedElement: group.element,
            description:
                '${a.branch}${b.branch}半合${group.element}（${group.branches.join('')}局缺一字）',
          ));
        }
      }
    }
  }

  void _checkBranchClash(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final pair = '${pillars[i].branch}${pillars[j].branch}';
        if (_branchClash.contains(pair)) {
          results.add(InteractionResult(
            type: InteractionType.branchClash6,
            nodeA: '${pillars[i].label}支${pillars[i].branch}',
            nodeB: '${pillars[j].label}支${pillars[j].branch}',
            description: '$pair六冲，动荡变化',
          ));
        }
      }
    }
  }

  void _checkBranchHarm(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final pair = '${pillars[i].branch}${pillars[j].branch}';
        final desc = _branchHarm[pair];
        if (desc != null) {
          results.add(InteractionResult(
            type: InteractionType.branchHarm6,
            nodeA: '${pillars[i].label}支${pillars[i].branch}',
            nodeB: '${pillars[j].label}支${pillars[j].branch}',
            description: desc,
          ));
        }
      }
    }
  }

  void _checkBranchPunish(
      List<InteractionResult> results, List<Pillar> pillars) {
    const punishGroups = [
      ['寅', '巳', '申'],
      ['丑', '戌', '未'],
      ['子', '卯'],
    ];
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final a = pillars[i].branch;
        final b = pillars[j].branch;
        String? desc;
        for (final g in punishGroups) {
          if (g.contains(a) && g.contains(b) && a != b) {
            desc = '$a$b相刑';
            if (a == '寅' && b == '巳') desc = '寅巳相刑，木火相生带刑';
            if (a == '寅' && b == '申') desc = '寅申相刑，金木相战';
            if (a == '巳' && b == '申') desc = '巳申相刑，火金相战';
            if (a == '子' && b == '卯') desc = '子卯相刑，无礼之刑';
            results.add(InteractionResult(
              type: InteractionType.branchPunish,
              nodeA: '${pillars[i].label}支$a',
              nodeB: '${pillars[j].label}支$b',
              description: desc,
            ));
            break;
          }
        }
      }
    }
  }
}
