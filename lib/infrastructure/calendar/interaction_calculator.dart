import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/interaction_result.dart';
import '../../domain/entities/pillar.dart';

class BaziInteractionCalculator {
  const BaziInteractionCalculator();

  static const _stemCombine = {
    '甲己': '土',
    '己甲': '土',
    '乙庚': '金',
    '庚乙': '金',
    '丙辛': '水',
    '辛丙': '水',
    '丁壬': '木',
    '壬丁': '木',
    '戊癸': '火',
    '癸戊': '火',
  };

  static const _branchCombine6 = {
    '子丑': '土',
    '丑子': '土',
    '寅亥': '木',
    '亥寅': '木',
    '卯戌': '火',
    '戌卯': '火',
    '辰酉': '金',
    '酉辰': '金',
    '巳申': '水',
    '申巳': '水',
    '午未': '土',
    '未午': '土',
  };

  static const _branchClash = {
    '子午',
    '午子',
    '丑未',
    '未丑',
    '寅申',
    '申寅',
    '卯酉',
    '酉卯',
    '辰戌',
    '戌辰',
    '巳亥',
    '亥巳',
  };

  static const _branchHarm = {
    '子未': '子未相害，子水被未土所害',
    '未子': '子未相害，子水被未土所害',
    '丑午': '丑午相害，丑土与午火相害',
    '午丑': '丑午相害，丑土与午火相害',
    '寅巳': '寅巳相害，寅木与巳火相害',
    '巳寅': '寅巳相害，寅木与巳火相害',
    '卯辰': '卯辰相害，卯木与辰土相害',
    '辰卯': '卯辰相害，卯木与辰土相害',
    '申亥': '申亥相害，申金与亥水相害',
    '亥申': '申亥相害，申金与亥水相害',
    '酉戌': '酉戌相害，酉金与戌土相害',
    '戌酉': '酉戌相害，酉金与戌土相害',
  };

  static const _branchBreak = {
    '子酉': '子酉相破，子水破酉金',
    '酉子': '子酉相破，子水破酉金',
    '卯午': '卯午相破，卯木破午火',
    '午卯': '卯午相破，卯木破午火',
    '辰丑': '辰丑相破，辰土与丑土相破',
    '丑辰': '辰丑相破，辰土与丑土相破',
    '戌未': '戌未相破，戌土与未土相破',
    '未戌': '戌未相破，戌土与未土相破',
    '寅亥': '寅亥相破，寅木与亥水相破',
    '亥寅': '寅亥相破，寅木与亥水相破',
    '巳申': '巳申相破，巳火与申金相破',
    '申巳': '巳申相破，巳火与申金相破',
  };

  static const _branchCombine3Groups =
      <({List<String> branches, String element, String middle})>[
    (branches: ['申', '子', '辰'], element: '水', middle: '子'),
    (branches: ['亥', '卯', '未'], element: '木', middle: '卯'),
    (branches: ['寅', '午', '戌'], element: '火', middle: '午'),
    (branches: ['巳', '酉', '丑'], element: '金', middle: '酉'),
  ];

  /// 半合：中神 + 生/库（如申子、子辰）。
  static const _branchHalfPairs = {
    '申子': '水',
    '子申': '水',
    '子辰': '水',
    '辰子': '水',
    '亥卯': '木',
    '卯亥': '木',
    '卯未': '木',
    '未卯': '木',
    '寅午': '火',
    '午寅': '火',
    '午戌': '火',
    '戌午': '火',
    '巳酉': '金',
    '酉巳': '金',
    '酉丑': '金',
    '丑酉': '金',
  };

  /// 拱合：生 + 库，缺中神（如申辰拱子）。
  static const _branchArchPairs = {
    '申辰': '水|子',
    '辰申': '水|子',
    '亥未': '木|卯',
    '未亥': '木|卯',
    '寅戌': '火|午',
    '戌寅': '火|午',
    '巳丑': '金|酉',
    '丑巳': '金|酉',
  };

  static const _punishPairDesc = {
    '寅巳': '寅巳相刑，无恩之刑',
    '巳寅': '寅巳相刑，无恩之刑',
    '寅申': '寅申相刑，无恩之刑',
    '申寅': '寅申相刑，无恩之刑',
    '巳申': '巳申相刑，无恩之刑',
    '申巳': '巳申相刑，无恩之刑',
    '丑戌': '丑戌相刑，无恩之刑',
    '戌丑': '丑戌相刑，无恩之刑',
    '丑未': '丑未相刑，持势之刑',
    '未丑': '丑未相刑，持势之刑',
    '戌未': '戌未相刑，持势之刑',
    '未戌': '戌未相刑，持势之刑',
    '子卯': '子卯相刑，无礼之刑',
    '卯子': '子卯相刑，无礼之刑',
  };

  static const _punishTripleGroups = [
    (branches: ['寅', '巳', '申'], name: '寅巳申三刑，无恩之刑'),
    (branches: ['丑', '戌', '未'], name: '丑戌未三刑，持势之刑'),
  ];

  static const _branchMeet3Groups = <({List<String> branches, String element})>[
    (branches: ['寅', '卯', '辰'], element: '木'),
    (branches: ['巳', '午', '未'], element: '火'),
    (branches: ['申', '酉', '戌'], element: '金'),
    (branches: ['亥', '子', '丑'], element: '水'),
  ];

  static const _selfPunishBranches = {'辰', '午', '酉', '亥'};

  List<InteractionResult> calculate(BaziChart chart) {
    final results = <InteractionResult>[];
    final pillars = chart.pillars;

    _checkStemCombine(results, pillars);
    _checkStemClash(results, pillars);
    _checkBranchCombine6(results, pillars);
    _checkBranchCombine3(results, pillars);
    _checkBranchMeet3(results, pillars);
    _checkBranchCombineHalf(results, pillars);
    _checkBranchArch(results, pillars);
    _checkBranchClash(results, pillars);
    _checkStemBranchBothClash(results, pillars);
    _checkBranchHarm(results, pillars);
    _checkBranchBreak(results, pillars);
    _checkBranchPunish(results, pillars);
    _checkBranchPunishTriple(results, pillars);
    _checkBranchSelfPunish(results, pillars);
    _checkFuYin(results, pillars);
    _checkFanYin(results, pillars);

    return _dedupePairwiseInteractions(
      _dedupeCompositeClashes(results, pillars),
    );
  }

  /// 四柱中多对柱位含同一地支组合时（如年申+月辰、日申+时辰），合并为一条。
  List<InteractionResult> _dedupePairwiseInteractions(
    List<InteractionResult> results,
  ) {
    const mergeTypes = {
      InteractionType.stemCombine,
      InteractionType.stemClash,
      InteractionType.branchCombine6,
      InteractionType.branchCombineHalf,
      InteractionType.branchArch,
      InteractionType.branchClash6,
      InteractionType.branchHarm6,
      InteractionType.branchBreak,
      InteractionType.branchPunish,
    };

    final passthrough = <InteractionResult>[];
    final buckets = <String, ({InteractionResult first, List<String> locs})>{};

    for (final r in results) {
      if (!mergeTypes.contains(r.type)) {
        passthrough.add(r);
        continue;
      }
      final key = _pairwiseDedupeKey(r);
      final loc = '${r.nodeA}↔${r.nodeB}';
      final existing = buckets[key];
      if (existing == null) {
        buckets[key] = (first: r, locs: [loc]);
      } else {
        existing.locs.add(loc);
      }
    }

    final merged = <InteractionResult>[];
    for (final bucket in buckets.values) {
      final first = bucket.first;
      if (bucket.locs.length == 1) {
        merged.add(first);
      } else {
        merged.add(InteractionResult(
          type: first.type,
          nodeA: first.nodeA,
          nodeB: first.nodeB,
          combinedElement: first.combinedElement,
          description: _mergedHiddenDesc(first.description, bucket.locs),
        ));
      }
    }

    return [...passthrough, ...merged];
  }

  String _pairwiseDedupeKey(InteractionResult r) {
    final a = r.nodeA;
    final b = r.nodeB;
    if (r.type == InteractionType.stemCombine ||
        r.type == InteractionType.stemClash) {
      final sa = _extractStemChar(a);
      final sb = _extractStemChar(b);
      return '${r.type.name}|${_canonicalStemPairLabel(sa, sb)}';
    }
    final ba = _extractBranchChar(a);
    final bb = _extractBranchChar(b);
    return '${r.type.name}|${_canonicalBranchPair(ba, bb)}';
  }

  String _canonicalBranchPair(String a, String b) =>
      a.compareTo(b) <= 0 ? '$a$b' : '$b$a';

  String _extractBranchChar(String node) {
    final match = RegExp(r'支(.)').firstMatch(node);
    return match?.group(1) ?? '';
  }

  String _extractStemChar(String node) {
    final hidden = RegExp(r'藏(.)').firstMatch(node);
    if (hidden != null) return hidden.group(1)!;
    final stem = RegExp(r'干(.)').firstMatch(node);
    return stem?.group(1) ?? '';
  }

  /// 天克地冲/反吟已涵盖天干冲与地支冲时，去掉重复的单项条目。
  List<InteractionResult> _dedupeCompositeClashes(
    List<InteractionResult> results,
    List<Pillar> pillars,
  ) {
    final fullClashLabels = <String>{};
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final a = pillars[i];
        final b = pillars[j];
        if (_isStemClash(a.stem, b.stem) &&
            _branchClash.contains('${a.branch}${b.branch}')) {
          fullClashLabels.add(_labelPairKey(a.label, b.label));
        }
      }
    }

    if (fullClashLabels.isEmpty) return results;

    var filtered = results.where((r) {
      if (r.type != InteractionType.stemClash &&
          r.type != InteractionType.branchClash6) {
        return true;
      }
      for (final pair in fullClashLabels) {
        final parts = pair.split('|');
        if (_matchesPillarLabels(r, parts[0], parts[1])) return false;
      }
      return true;
    }).toList();

    final fanYinPairs = filtered
        .where((r) => r.type == InteractionType.fanYin)
        .map(_nodePairKey)
        .toSet();
    filtered = filtered.where((r) {
      if (r.type != InteractionType.stemBranchBothClash) return true;
      return !fanYinPairs.contains(_nodePairKey(r));
    }).toList();

    return filtered;
  }

  String _labelPairKey(String a, String b) =>
      a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

  String _nodePairKey(InteractionResult r) {
    final a = r.nodeA;
    final b = r.nodeB;
    return a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
  }

  bool _matchesPillarLabels(
    InteractionResult r,
    String labelA,
    String labelB,
  ) {
    bool hasLabel(String node, String label) => node.startsWith(label);
    return (hasLabel(r.nodeA, labelA) && hasLabel(r.nodeB, labelB)) ||
        (hasLabel(r.nodeA, labelB) && hasLabel(r.nodeB, labelA));
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
        final a = pillars[i].stem;
        final b = pillars[j].stem;
        if (_isStemClash(a, b)) {
          results.add(InteractionResult(
            type: InteractionType.stemClash,
            nodeA: '${pillars[i].label}干$a',
            nodeB: '${pillars[j].label}干$b',
            description: '$a$b天干相冲',
          ));
        }
      }
    }
  }

  bool _isStemClash(String a, String b) {
    const map = {
      '甲': '庚',
      '庚': '甲',
      '乙': '辛',
      '辛': '乙',
      '丙': '壬',
      '壬': '丙',
      '丁': '癸',
      '癸': '丁',
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

  void _checkBranchMeet3(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (final group in _branchMeet3Groups) {
      final branchSet = pillars.map((p) => p.branch).toSet();
      if (!group.branches.every(branchSet.contains)) continue;
      final hits =
          pillars.where((p) => group.branches.contains(p.branch)).toList();
      final nodes = hits.map((p) => '${p.label}支${p.branch}').join('、');
      results.add(InteractionResult(
        type: InteractionType.branchCombineMeet3,
        nodeA: '${hits[0].label}支${hits[0].branch}',
        nodeB: '${hits[1].label}支${hits[1].branch}',
        combinedElement: group.element,
        description:
            '${group.branches.join('')}三会${group.element}局（$nodes）',
      ));
    }
  }

  bool _hasFullCombine3(List<Pillar> pillars, List<String> groupBranches) {
    final branchSet = pillars.map((p) => p.branch).toSet();
    return groupBranches.every(branchSet.contains);
  }

  void _checkBranchCombineHalf(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final pair = '${pillars[i].branch}${pillars[j].branch}';
        final element = _branchHalfPairs[pair];
        if (element == null) continue;
        if (_hasFullCombine3(pillars, _groupForHalf(pair)!)) continue;
        results.add(InteractionResult(
          type: InteractionType.branchCombineHalf,
          nodeA: '${pillars[i].label}支${pillars[i].branch}',
          nodeB: '${pillars[j].label}支${pillars[j].branch}',
          combinedElement: element,
          description: '$pair半合$element',
        ));
      }
    }
  }

  List<String>? _groupForHalf(String pair) {
    for (final g in _branchCombine3Groups) {
      if (g.branches.contains(pair[0]) && g.branches.contains(pair[1])) {
        return g.branches;
      }
    }
    return null;
  }

  void _checkBranchArch(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final pair = '${pillars[i].branch}${pillars[j].branch}';
        final arch = _branchArchPairs[pair];
        if (arch == null) continue;
        final parts = arch.split('|');
        final element = parts[0];
        final middle = parts[1];
        final group = _branchCombine3Groups
            .firstWhere((g) => g.branches.contains(middle));
        if (_hasFullCombine3(pillars, group.branches)) continue;
        results.add(InteractionResult(
          type: InteractionType.branchArch,
          nodeA: '${pillars[i].label}支${pillars[i].branch}',
          nodeB: '${pillars[j].label}支${pillars[j].branch}',
          combinedElement: element,
          description: '$pair拱$middle，合${group.element}局',
        ));
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

  void _checkStemBranchBothClash(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final a = pillars[i];
        final b = pillars[j];
        if (_isStemClash(a.stem, b.stem) &&
            _branchClash.contains('${a.branch}${b.branch}')) {
          results.add(InteractionResult(
            type: InteractionType.stemBranchBothClash,
            nodeA: '${a.label}${a.stem}${a.branch}',
            nodeB: '${b.label}${b.stem}${b.branch}',
            description:
                '${a.stem}${a.branch}与${b.stem}${b.branch}天克地冲',
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

  void _checkBranchBreak(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final pair = '${pillars[i].branch}${pillars[j].branch}';
        final desc = _branchBreak[pair];
        if (desc != null) {
          results.add(InteractionResult(
            type: InteractionType.branchBreak,
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
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final pair = '${pillars[i].branch}${pillars[j].branch}';
        final desc = _punishPairDesc[pair];
        if (desc != null) {
          results.add(InteractionResult(
            type: InteractionType.branchPunish,
            nodeA: '${pillars[i].label}支${pillars[i].branch}',
            nodeB: '${pillars[j].label}支${pillars[j].branch}',
            description: desc,
          ));
        }
      }
    }
  }

  void _checkBranchPunishTriple(
      List<InteractionResult> results, List<Pillar> pillars) {
    final branchSet = pillars.map((p) => p.branch).toSet();
    for (final group in _punishTripleGroups) {
      if (!group.branches.every(branchSet.contains)) continue;
      final hits =
          pillars.where((p) => group.branches.contains(p.branch)).toList();
      final nodes = hits.map((p) => '${p.label}支${p.branch}').join('、');
      results.add(InteractionResult(
        type: InteractionType.branchPunishTriple,
        nodeA: '${hits[0].label}支${hits[0].branch}',
        nodeB: '${hits[1].label}支${hits[1].branch}',
        description: '${group.name}（$nodes）',
      ));
    }
  }

  void _checkBranchSelfPunish(
      List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final a = pillars[i].branch;
        final b = pillars[j].branch;
        if (a == b && _selfPunishBranches.contains(a)) {
          results.add(InteractionResult(
            type: InteractionType.branchSelfPunish,
            nodeA: '${pillars[i].label}支$a',
            nodeB: '${pillars[j].label}支$b',
            description: '$a自刑，同支相见',
          ));
        }
      }
    }
  }

  void _checkFuYin(List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final a = pillars[i];
        final b = pillars[j];
        if (a.stem == b.stem && a.branch == b.branch) {
          results.add(InteractionResult(
            type: InteractionType.fuYin,
            nodeA: '${a.label}${a.stem}${a.branch}',
            nodeB: '${b.label}${b.stem}${b.branch}',
            description: '${a.stem}${a.branch}伏吟，整柱重复',
          ));
        } else if (a.stem == b.stem) {
          results.add(InteractionResult(
            type: InteractionType.fuYin,
            nodeA: '${a.label}干${a.stem}',
            nodeB: '${b.label}干${b.stem}',
            description: '${a.stem}天干伏吟',
          ));
        } else if (a.branch == b.branch) {
          results.add(InteractionResult(
            type: InteractionType.fuYin,
            nodeA: '${a.label}支${a.branch}',
            nodeB: '${b.label}支${b.branch}',
            description: '${a.branch}地支伏吟',
          ));
        }
      }
    }
  }

  void _checkFanYin(List<InteractionResult> results, List<Pillar> pillars) {
    for (var i = 0; i < pillars.length; i++) {
      for (var j = i + 1; j < pillars.length; j++) {
        final a = pillars[i];
        final b = pillars[j];
        if (_isStemClash(a.stem, b.stem) &&
            _branchClash.contains('${a.branch}${b.branch}')) {
          results.add(InteractionResult(
            type: InteractionType.fanYin,
            nodeA: '${a.label}${a.stem}${a.branch}',
            nodeB: '${b.label}${b.stem}${b.branch}',
            description:
                '${a.stem}${a.branch}与${b.stem}${b.branch}反吟，天冲地冲',
          ));
        }
      }
    }
  }

  /// 藏干与透干、藏干之间的天干五合 / 相冲（四柱明干关系已在 [calculate] 中）。
  /// 同一组天干关系只展示一条，具体柱位合并到描述中。
  List<InteractionResult> calculateHiddenStemInteractions(BaziChart chart) {
    final nodes = <({String id, String stem})>[];
    for (final p in chart.pillars) {
      nodes.add((id: '${p.label}干${p.stem}', stem: p.stem));
      for (final h in p.hiddenStems) {
        nodes.add((id: '${p.label}支${p.branch}藏${h.stem}', stem: h.stem));
      }
    }

    final combineBuckets = <String, List<String>>{};
    final clashBuckets = <String, List<String>>{};

    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final a = nodes[i];
        final b = nodes[j];
        if (_isSurfaceStemPair(a.id, b.id)) continue;

        final pairLabel = _canonicalStemPairLabel(a.stem, b.stem);
        final loc = '${a.id}↔${b.id}';
        final combineKey = '${a.stem}|${b.stem}';
        final element = _stemCombine[combineKey] ??
            _stemCombine['${b.stem}${a.stem}'];
        if (element != null) {
          combineBuckets.putIfAbsent('$pairLabel|$element', () => []).add(loc);
          continue;
        }
        if (_isStemClash(a.stem, b.stem)) {
          clashBuckets.putIfAbsent(pairLabel, () => []).add(loc);
        }
      }
    }

    final results = <InteractionResult>[];
    for (final entry in combineBuckets.entries) {
      final parts = entry.key.split('|');
      final pairLabel = parts[0];
      final element = parts[1];
      final locs = entry.value;
      results.add(InteractionResult(
        type: InteractionType.stemCombine,
        nodeA: locs.first.split('↔').first,
        nodeB: locs.first.split('↔').last,
        combinedElement: element,
        description: _mergedHiddenDesc(
          '藏干 $pairLabel合化$element',
          locs,
        ),
      ));
    }
    for (final entry in clashBuckets.entries) {
      final pairLabel = entry.key;
      final locs = entry.value;
      results.add(InteractionResult(
        type: InteractionType.stemClash,
        nodeA: locs.first.split('↔').first,
        nodeB: locs.first.split('↔').last,
        description: _mergedHiddenDesc(
          '藏干 $pairLabel天干相冲',
          locs,
        ),
      ));
    }
    return results;
  }

  String _canonicalStemPairLabel(String a, String b) =>
      a.compareTo(b) <= 0 ? '$a$b' : '$b$a';

  String _mergedHiddenDesc(String headline, List<String> locations) {
    if (locations.length <= 1) {
      return locations.isEmpty ? headline : '$headline（${locations.first}）';
    }
    return '$headline（${locations.join('；')}）';
  }

  bool _isSurfaceStemPair(String idA, String idB) {
    bool surface(String id) => id.contains('干') && !id.contains('藏');
    return surface(idA) && surface(idB);
  }
}
