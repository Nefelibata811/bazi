import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/shensha_item.dart';
import '../../domain/services/shensha_calculator.dart';

class RuleShenshaCalculator implements ShenshaCalculator {
  const RuleShenshaCalculator();

  static const _tianYiGuiRen = {
    '甲': ['丑', '未'], '乙': ['子', '申'], '丙': ['亥', '酉'], '丁': ['亥', '酉'],
    '戊': ['丑', '未'], '己': ['子', '申'], '庚': ['丑', '未'], '辛': ['寅', '午'],
    '壬': ['卯', '巳'], '癸': ['卯', '巳'],
  };
  static const _taiJiGuiRen = {
    '甲': ['子', '午'], '乙': ['子', '午'], '丙': ['卯', '酉'], '丁': ['卯', '酉'],
    '戊': ['辰', '戌', '丑', '未'], '己': ['辰', '戌', '丑', '未'],
    '庚': ['寅', '亥'], '辛': ['寅', '亥'], '壬': ['巳', '申'], '癸': ['巳', '申'],
  };
  static const _fuXing = {
    '甲': ['寅', '子'], '乙': ['卯', '丑'], '丙': ['寅', '子'], '丁': ['亥'],
    '戊': ['申'], '己': ['未'], '庚': ['午'], '辛': ['巳'],
    '壬': ['辰'], '癸': ['卯', '丑'],
  };
  static const _wenChang = {
    '甲': '巳', '乙': '午', '丙': '申', '丁': '酉', '戊': '申',
    '己': '酉', '庚': '亥', '辛': '子', '壬': '寅', '癸': '卯',
  };
  static const _luShen = {
    '甲': '寅', '乙': '卯', '丙': '巳', '丁': '午', '戊': '巳',
    '己': '午', '庚': '申', '辛': '酉', '壬': '亥', '癸': '子',
  };
  static const _yangRen = {
    '甲': '卯', '乙': '寅', '丙': '午', '丁': '巳', '戊': '午',
    '己': '巳', '庚': '酉', '辛': '申', '壬': '子', '癸': '亥',
  };
  static const _jinYu = {
    '甲': '辰', '乙': '巳', '丙': '未', '丁': '申', '戊': '未',
    '己': '申', '庚': '戌', '辛': '亥', '壬': '丑', '癸': '寅',
  };
  static const _feiRen = {
    '甲': '酉', '乙': '申', '丙': '子', '丁': '亥', '戊': '子',
    '己': '亥', '庚': '卯', '辛': '寅', '壬': '午', '癸': '巳',
  };
  static const _guoYinGuiRen = {
    '甲': '戌', '乙': '亥', '丙': '丑', '丁': '寅', '戊': '丑',
    '己': '寅', '庚': '辰', '辛': '巳', '壬': '未', '癸': '申',
  };
  static const _tianChuGuiRen = {
    '甲': '巳', '乙': '午', '丙': '巳', '丁': '午',
    '戊': '申', '己': '酉', '庚': '亥', '辛': '子',
    '壬': '寅', '癸': '卯',
  };
  static const _hongYan = {
    '甲': '午', '乙': '午', '丙': '寅', '丁': '未', '戊': '辰',
    '己': '辰', '庚': '戌', '辛': '酉', '壬': '子', '癸': '申',
  };
  static const _liuXia = {
    '甲': '酉', '乙': '戌', '丙': '未', '丁': '申', '戊': '巳',
    '己': '午', '庚': '辰', '辛': '卯', '壬': '亥', '癸': '寅',
  };
  static const _xueTang = {
    '甲': '亥', '乙': '午', '丙': '寅', '丁': '酉', '戊': '寅',
    '己': '酉', '庚': '巳', '辛': '子', '壬': '申', '癸': '卯',
  };
  static const _ciGuan = {
    '甲': '寅', '乙': '午', '丙': '巳', '丁': '酉', '戊': '巳',
    '己': '酉', '庚': '申', '辛': '子', '壬': '亥', '癸': '卯',
  };

  static const _tianDe = {
    '寅': '丁', '卯': '甲', '辰': '壬', '巳': '辛',
    '午': '亥', '未': '甲', '申': '癸', '酉': '寅',
    '戌': '丙', '亥': '乙', '子': '巳', '丑': '庚',
  };
  static const _yueDe = {
    '寅': '丙', '午': '丙', '戌': '丙',
    '亥': '甲', '卯': '甲', '未': '甲',
    '申': '壬', '子': '壬', '辰': '壬',
    '巳': '庚', '酉': '庚', '丑': '庚',
  };

  static const _yiMa = {
    '申': '寅', '子': '寅', '辰': '寅', '寅': '申', '午': '申', '戌': '申',
    '巳': '亥', '酉': '亥', '丑': '亥', '亥': '巳', '卯': '巳', '未': '巳',
  };
  static const _taoHua = {
    '申': '酉', '子': '酉', '辰': '酉', '寅': '卯', '午': '卯', '戌': '卯',
    '巳': '午', '酉': '午', '丑': '午', '亥': '子', '卯': '子', '未': '子',
  };
  static const _huaGai = {
    '申': '辰', '子': '辰', '辰': '辰', '寅': '戌', '午': '戌', '戌': '戌',
    '巳': '丑', '酉': '丑', '丑': '丑', '亥': '未', '卯': '未', '未': '未',
  };
  static const _wangShen = {
    '申': '亥', '子': '亥', '辰': '亥', '寅': '巳', '午': '巳', '戌': '巳',
    '巳': '申', '酉': '申', '丑': '申', '亥': '寅', '卯': '寅', '未': '寅',
  };
  static const _jieSha = {
    '申': '巳', '子': '巳', '辰': '巳', '寅': '亥', '午': '亥', '戌': '亥',
    '巳': '寅', '酉': '寅', '丑': '寅', '亥': '申', '卯': '申', '未': '申',
  };
  static const _jiangXing = {
    '申': '子', '子': '子', '辰': '子', '寅': '午', '午': '午', '戌': '午',
    '巳': '酉', '酉': '酉', '丑': '酉', '亥': '卯', '卯': '卯', '未': '卯',
  };
  static const _zaiSha = {
    '申': '午', '子': '午', '辰': '午', '寅': '子', '午': '子', '戌': '子',
    '巳': '卯', '酉': '卯', '丑': '卯', '亥': '酉', '卯': '酉', '未': '酉',
  };

  static const _hongLuan = {
    '子': '卯', '丑': '寅', '寅': '丑', '卯': '子',
    '辰': '亥', '巳': '戌', '午': '酉', '未': '申',
    '申': '未', '酉': '午', '戌': '巳', '亥': '辰',
  };
  static const _tianXi = {
    '子': '酉', '丑': '申', '寅': '未', '卯': '午',
    '辰': '巳', '巳': '辰', '午': '卯', '未': '寅',
    '申': '丑', '酉': '子', '戌': '亥', '亥': '戌',
  };
  static const _guChen = {
    '亥': '寅', '子': '寅', '丑': '寅', '寅': '巳', '卯': '巳', '辰': '巳',
    '巳': '申', '午': '申', '未': '申', '申': '亥', '酉': '亥', '戌': '亥',
  };
  static const _guaSu = {
    '亥': '戌', '子': '戌', '丑': '戌', '寅': '丑', '卯': '丑', '辰': '丑',
    '巳': '辰', '午': '辰', '未': '辰', '申': '未', '酉': '未', '戌': '未',
  };
  static const _sangMen = {
    '子': '寅', '丑': '卯', '寅': '辰', '卯': '巳', '辰': '午', '巳': '未',
    '午': '申', '未': '酉', '申': '戌', '酉': '亥', '戌': '子', '亥': '丑',
  };
  static const _diaoKe = {
    '子': '戌', '丑': '亥', '寅': '子', '卯': '丑', '辰': '寅', '巳': '卯',
    '午': '辰', '未': '巳', '申': '午', '酉': '未', '戌': '申', '亥': '酉',
  };
  static const _piMa = {
    '子': '酉', '丑': '戌', '寅': '亥', '卯': '子', '辰': '丑', '巳': '寅',
    '午': '卯', '未': '辰', '申': '巳', '酉': '午', '戌': '未', '亥': '申',
  };
  static const _xueRen = {
    '寅': '丑', '卯': '未', '辰': '寅', '巳': '申',
    '午': '卯', '未': '酉', '申': '辰', '酉': '戌',
    '戌': '巳', '亥': '亥', '子': '午', '丑': '子',
  };
  static const _tianYiYue = {
    '寅': '丑', '卯': '寅', '辰': '卯', '巳': '辰',
    '午': '巳', '未': '午', '申': '未', '酉': '申',
    '戌': '酉', '亥': '戌', '子': '亥', '丑': '子',
  };

  static const _deXiu = {
    '寅': ['丙', '丁', '戊', '癸'], '午': ['丙', '丁', '戊', '癸'], '戌': ['丙', '丁', '戊', '癸'],
    '申': ['壬', '癸', '戊', '己', '丙', '辛', '甲'], '子': ['壬', '癸', '戊', '己', '丙', '辛', '甲'], '辰': ['壬', '癸', '戊', '己', '丙', '辛', '甲'],
    '巳': ['庚', '辛', '乙'], '酉': ['庚', '辛', '乙'], '丑': ['庚', '辛', '乙'],
    '亥': ['甲', '乙', '丁', '壬'], '卯': ['甲', '乙', '丁', '壬'], '未': ['甲', '乙', '丁', '壬'],
  };

  // === 日柱特殊组合 ===
  static const _kuiGangDays = {'庚辰', '庚戌', '壬辰', '戊戌'};
  static const _shiEDaBaiDays = {
    '甲辰', '乙巳', '丙申', '丁亥', '戊戌', '己丑',
    '庚辰', '辛巳', '壬申', '癸亥',
  };
  static const _guLuanDays = {
    '甲寅', '乙巳', '丙午', '丁巳', '戊午', '辛亥', '壬子', '癸巳',
  };
  static const _yinCuoYangChaDays = {
    '丙子', '丙午', '丁丑', '丁未', '戊寅', '戊申',
    '辛卯', '辛酉', '壬辰', '壬戌', '癸巳', '癸亥',
  };
  static const _shiLingDays = {
    '甲辰', '乙亥', '丙辰', '丁酉', '戊午', '庚戌', '庚寅', '辛亥', '壬寅', '癸未',
  };
  static const _baZhuanDays = {
    '甲寅', '乙卯', '丁未', '戊戌', '己未', '庚申', '辛酉', '癸丑',
  };
  static const _liuXiuDays = {
    '丙午', '丁未', '戊子', '戊午', '己丑', '己未',
  };
  static const _jiuChouDays = {
    '丁酉', '戊子', '戊午', '己卯', '己酉', '辛卯', '辛酉', '壬子', '壬午',
  };
  static const _tianSheDays = {
    '春': ['戊寅'], '夏': ['甲午'], '秋': ['戊申'], '冬': ['甲子'],
  };

  @override
  Future<List<ShenshaItem>> calculate(BaziChart chart) async {
    final results = <ShenshaItem>[];
    final ds = chart.dayMaster;
    final ys = chart.year.stem;
    final yb = chart.year.branch;
    final db = chart.day.branch;
    final mb = chart.month.branch;
    final dgz = '${chart.day.stem}${chart.day.branch}';

    _checkTianYi(results, chart, ds);
    _checkTianYi(results, chart, ys);
    _checkTaiJi(results, chart, ds);
    _checkTaiJi(results, chart, ys);
    _checkFuXing(results, chart, ds);
    _checkFuXing(results, chart, ys);
    _checkStemBased(results, chart, ds, '日干');
    _checkStemBased(results, chart, ys, '年干');
    _checkXueTangCiGuan(results, chart, ds);
    _checkXueTangCiGuan(results, chart, ys);
    _checkBranchBased(results, chart, yb, '年支');
    _checkBranchBased(results, chart, db, '日支');
    _checkYearBranchSingle(results, chart, yb);
    _checkTianDe(results, chart, mb);
    _checkYueDe(results, chart, mb);
    _checkDeXiu(results, chart, mb);
    _checkKuiGang(results, chart, dgz);
    _checkShiEDaBai(results, chart, dgz);
    _checkGuLuan(results, chart, dgz);
    _checkYinCuoYangCha(results, chart, dgz);
    _checkTianShe(results, chart);
    _checkKongWang(results, chart);
    _checkFeiRen(results, chart, ds);
    _checkFeiRen(results, chart, ys);
    _checkGuoYin(results, chart, ds);
    _checkGuoYin(results, chart, ys);
    _checkTianChu(results, chart, ds);
    _checkTianChu(results, chart, ys);
    _checkHongYan(results, chart, ds);
    _checkLiuXia(results, chart, ds);
    _checkYearBranchFixed(results, chart, yb);
    _checkMonthBranchFixed(results, chart, mb);
    _checkPillarDays(results, chart, dgz);
    _checkSiFeiDay(results, chart, dgz);
    _checkZhuan(results, chart, dgz);
    _checkSanQi(results, chart);
    _checkJinShen(results, chart);
    _checkTianLuoDiWang(results, chart);
    _checkTongZi(results, chart);

    return results;
  }

  void _add(List<ShenshaItem> results, ShenshaItem item) {
    final key = '${item.name}|${item.target}';
    if (results.any((e) => '${e.name}|${e.target}' == key)) return;
    results.add(item);
  }

  void _checkTianYi(List<ShenshaItem> results, BaziChart chart, String stem) {
    final b = _tianYiGuiRen[stem]; if (b == null) return;
    final label = stem == chart.dayMaster ? '日干' : '年干';
    for (final p in chart.pillars) {
      if (b.contains(p.branch)) {
        _add(results, ShenshaItem(name: '天乙贵人', target: '${p.label}支${p.branch}',
            description: '${label}$stem见${p.branch}为天乙贵人，主逢凶化吉、贵人相助', pillar: p.label));
      }
    }
  }

  void _checkTaiJi(List<ShenshaItem> results, BaziChart chart, String stem) {
    final b = _taiJiGuiRen[stem]; if (b == null) return;
    final label = stem == chart.dayMaster ? '日干' : '年干';
    for (final p in chart.pillars) {
      if (b.contains(p.branch)) {
        _add(results, ShenshaItem(name: '太极贵人', target: '${p.label}支${p.branch}',
            description: '${label}$stem见${p.branch}为太极贵人，主智慧超群、有玄学天赋', pillar: p.label));
      }
    }
  }

  void _checkFuXing(List<ShenshaItem> results, BaziChart chart, String stem) {
    final branches = _fuXing[stem]; if (branches == null) return;
    final label = stem == chart.dayMaster ? '日干' : '年干';
    for (final p in chart.pillars) {
      if (branches.contains(p.branch)) {
        _add(results, ShenshaItem(name: '福星贵人', target: '${p.label}支${p.branch}',
            description: '${label}$stem见${p.branch}为福星贵人，主福寿安康', pillar: p.label));
      }
    }
  }

  void _checkStemBased(List<ShenshaItem> results, BaziChart chart, String ds, String bl) {
    final checks = <String, Map<String, String>>{
      '文昌': _wenChang, '禄神': _luShen, '羊刃': _yangRen, '金舆': _jinYu,
    };
    final descs = {
      '文昌': '$bl$ds见%s为文昌，主聪慧好学、利于考试与文书',
      '禄神': '$bl$ds见%s为禄神（临官），主福禄、自立与事业根基',
      '羊刃': '$bl$ds见%s为羊刃，主刚强果断，过旺则宜制化',
      '金舆': '$bl$ds见%s为金舆，主车马衣食、出行顺遂之象',
    };
    for (final e in checks.entries) {
      final tb = e.value[ds]; if (tb == null) continue;
      for (final p in chart.pillars) {
        if (p.branch == tb) {
          _add(results, ShenshaItem(name: e.key, target: '${p.label}支${p.branch}',
              description: descs[e.key]!.replaceFirst('%s', p.branch), pillar: p.label));
        }
      }
    }
  }

  void _checkXueTangCiGuan(List<ShenshaItem> results, BaziChart chart, String stem) {
    final label = stem == chart.dayMaster ? '日干' : '年干';
    final xt = _xueTang[stem];
    final cg = _ciGuan[stem];
    for (final p in chart.pillars) {
      if (xt != null && p.branch == xt) {
        _add(results, ShenshaItem(name: '学堂', target: '${p.label}支${p.branch}',
            description: '${label}$stem见${p.branch}为学堂，主学业有成、文采出众', pillar: p.label));
      }
      if (cg != null && p.branch == cg) {
        _add(results, ShenshaItem(name: '词馆', target: '${p.label}支${p.branch}',
            description: '${label}$stem见${p.branch}为词馆，主文章锦绣、有文学天赋', pillar: p.label));
      }
    }
  }

  void _checkBranchBased(List<ShenshaItem> results, BaziChart chart, String bb, String bl) {
    final rules = <String, Map<String, String>>{
      '驿马': _yiMa, '桃花': _taoHua, '华盖': _huaGai,
      '亡神': _wangShen, '劫煞': _jieSha, '将星': _jiangXing, '灾煞': _zaiSha,
    };
    final descs = {
      '驿马': '$bl$bb见%s为驿马，主动荡、迁移、奔波',
      '桃花': '$bl$bb见%s为桃花（咸池），主人缘情感，须结合十神',
      '华盖': '$bl$bb见%s为华盖，主学术、艺术、玄学气质',
      '亡神': '$bl$bb见%s为亡神，主官非口舌，亦为魄力',
      '劫煞': '$bl$bb见%s为劫煞，主是非破败，宜结合用神',
      '将星': '$bl$bb见%s为将星，主权威、统御与决断力',
      '灾煞': '$bl$bb见%s为灾煞，主意外波折，宜慎行',
    };
    for (final e in rules.entries) {
      final tb = e.value[bb]; if (tb == null) continue;
      for (final p in chart.pillars) {
        if (p.branch == tb) {
          _add(results, ShenshaItem(name: e.key, target: '${p.label}支${p.branch}',
              description: descs[e.key]!.replaceFirst('%s', p.branch), pillar: p.label));
        }
      }
    }
  }

  void _checkTianDe(List<ShenshaItem> results, BaziChart chart, String mb) {
    final ts = _tianDe[mb]; if (ts == null) return;
    for (final p in chart.pillars) {
      if (p.stem == ts) {
        _add(results, ShenshaItem(name: '天德贵人', target: '${p.label}干${p.stem}',
            description: '月支$mb见${p.stem}为天德贵人，上天庇护，主逢凶化吉、福泽深厚', pillar: p.label));
      }
    }
  }

  void _checkYueDe(List<ShenshaItem> results, BaziChart chart, String mb) {
    final ts = _yueDe[mb]; if (ts == null) return;
    for (final p in chart.pillars) {
      if (p.stem == ts) {
        _add(results, ShenshaItem(name: '月德贵人', target: '${p.label}干${p.stem}',
            description: '月支$mb见${p.stem}为月德贵人，得天地月德之力，主温和善良', pillar: p.label));
      }
    }
  }

  void _checkDeXiu(List<ShenshaItem> results, BaziChart chart, String mb) {
    final stems = _deXiu[mb]; if (stems == null) return;
    for (final p in chart.pillars) {
      if (stems.contains(p.stem)) {
        _add(results, ShenshaItem(name: '德秀贵人', target: '${p.label}干${p.stem}',
            description: '月支$mb见${p.stem}为德秀贵人，主品德优良、才华秀美、福泽绵长', pillar: p.label));
      }
    }
  }

  void _checkYearBranchSingle(List<ShenshaItem> results, BaziChart chart, String yb) {
    final hl = _hongLuan[yb], tx = _tianXi[yb], gc = _guChen[yb], gs = _guaSu[yb];
    for (final p in chart.pillars) {
      if (hl != null && p.branch == hl) {
        _add(results, ShenshaItem(name: '红鸾', target: '${p.label}支${p.branch}',
            description: '年支$yb见${p.branch}为红鸾，主婚恋喜庆、人缘和合', pillar: p.label));
      }
      if (tx != null && p.branch == tx) {
        _add(results, ShenshaItem(name: '天喜', target: '${p.label}支${p.branch}',
            description: '年支$yb见${p.branch}为天喜，主喜庆、好事将近', pillar: p.label));
      }
      if (gc != null && p.branch == gc) {
        _add(results, ShenshaItem(name: '孤辰', target: '${p.label}支${p.branch}',
            description: '年支$yb见${p.branch}为孤辰，主性格孤高，宜修身养性', pillar: p.label));
      }
      if (gs != null && p.branch == gs) {
        _add(results, ShenshaItem(name: '寡宿', target: '${p.label}支${p.branch}',
            description: '年支$yb见${p.branch}为寡宿，主寡静少合，感情宜审慎', pillar: p.label));
      }
    }
  }

  void _checkKuiGang(List<ShenshaItem> results, BaziChart chart, String dgz) {
    if (!_kuiGangDays.contains(dgz)) return;
    _add(results, ShenshaItem(name: '魁罡', target: '日柱$dgz',
        description: '日柱$dgz为魁罡，性格刚毅果决，有威权领导之象，忌刑冲过甚', pillar: '日'));
  }

  void _checkShiEDaBai(List<ShenshaItem> results, BaziChart chart, String dgz) {
    if (!_shiEDaBaiDays.contains(dgz)) return;
    _add(results, ShenshaItem(name: '十恶大败', target: '日柱$dgz',
        description: '日柱$dgz为十恶大败，主钱财难聚，宜勤俭持家、忌投机取巧', pillar: '日'));
  }

  void _checkGuLuan(List<ShenshaItem> results, BaziChart chart, String dgz) {
    if (!_guLuanDays.contains(dgz)) return;
    _add(results, ShenshaItem(name: '孤鸾煞', target: '日柱$dgz',
        description: '日柱$dgz为孤鸾煞，主婚姻感情多有波折，宜晚婚或以合解冲', pillar: '日'));
  }

  void _checkYinCuoYangCha(List<ShenshaItem> results, BaziChart chart, String dgz) {
    if (!_yinCuoYangChaDays.contains(dgz)) return;
    _add(results, ShenshaItem(name: '阴错阳差', target: '日柱$dgz',
        description: '日柱$dgz为阴错阳差，主婚姻不顺、夫妻关系欠和、家庭易生摩擦', pillar: '日'));
  }

  void _checkTianShe(List<ShenshaItem> results, BaziChart chart) {
    final mb = chart.month.branch;
    String s;
    if (['寅', '卯', '辰'].contains(mb)) { s = '春'; }
    else if (['巳', '午', '未'].contains(mb)) { s = '夏'; }
    else if (['申', '酉', '戌'].contains(mb)) { s = '秋'; }
    else { s = '冬'; }
    final dgz = '${chart.day.stem}${chart.day.branch}';
    final td = _tianSheDays[s];
    if (td == null || !td.contains(dgz)) return;
    _add(results, ShenshaItem(name: '天赦日', target: '日柱$dgz',
        description: '$s季$dgz为天赦日，上天赦免万物之日，主逢凶化吉、诸事顺遂', pillar: '日'));
  }

  void _checkKongWang(List<ShenshaItem> results, BaziChart chart) {
    final dk = chart.day.xunKong, yk = chart.year.xunKong;
    for (final p in chart.pillars) {
      if (p.label == '日' || p.label == '年') continue;
      final kongs = <String>{};
      if (dk.isNotEmpty && dk.contains(p.branch)) kongs.add('日空');
      if (yk.isNotEmpty && yk.contains(p.branch)) kongs.add('年空');
      if (kongs.isNotEmpty) {
        _add(results, ShenshaItem(name: '空亡', target: '${p.label}支${p.branch}',
            description: '${p.label}支${p.branch}落入${kongs.join('/')}（$dk/$yk），主虚浮无力、有名无实', pillar: p.label));
      }
    }
  }

  void _checkFeiRen(List<ShenshaItem> results, BaziChart chart, String stem) {
    final tb = _feiRen[stem]; if (tb == null) return;
    final label = stem == chart.dayMaster ? '日干' : '年干';
    for (final p in chart.pillars) {
      if (p.branch == tb) {
        _add(results, ShenshaItem(name: '飞刃', target: '${p.label}支${p.branch}',
            description: '${label}$stem见${p.branch}为飞刃（羊刃对冲），主突如其来的冲突与变动', pillar: p.label));
      }
    }
  }

  void _checkGuoYin(List<ShenshaItem> results, BaziChart chart, String stem) {
    final tb = _guoYinGuiRen[stem]; if (tb == null) return;
    final label = stem == chart.dayMaster ? '日干' : '年干';
    for (final p in chart.pillars) {
      if (p.branch == tb) {
        _add(results, ShenshaItem(name: '国印贵人', target: '${p.label}支${p.branch}',
            description: '${label}$stem见${p.branch}为国印贵人，主权柄、文书、公职之贵', pillar: p.label));
      }
    }
  }

  void _checkTianChu(List<ShenshaItem> results, BaziChart chart, String stem) {
    final tb = _tianChuGuiRen[stem]; if (tb == null) return;
    final label = stem == chart.dayMaster ? '日干' : '年干';
    for (final p in chart.pillars) {
      if (p.branch == tb) {
        _add(results, ShenshaItem(name: '天厨贵人', target: '${p.label}支${p.branch}',
            description: '${label}$stem见${p.branch}为天厨贵人（食神之禄），主食禄丰厚、安逸享福', pillar: p.label));
      }
    }
  }

  void _checkHongYan(List<ShenshaItem> results, BaziChart chart, String ds) {
    final tb = _hongYan[ds]; if (tb == null) return;
    for (final p in chart.pillars) {
      if (p.branch == tb) {
        _add(results, ShenshaItem(name: '红艳煞', target: '${p.label}支${p.branch}',
            description: '日干$ds见${p.branch}为红艳煞，主异性缘佳、情感丰富，易有风流韵事', pillar: p.label));
      }
    }
  }

  void _checkLiuXia(List<ShenshaItem> results, BaziChart chart, String ds) {
    final tb = _liuXia[ds]; if (tb == null) return;
    for (final p in chart.pillars) {
      if (p.branch == tb) {
        _add(results, ShenshaItem(name: '流霞', target: '${p.label}支${p.branch}',
            description: '日干$ds见${p.branch}为流霞，男主他乡死、女主产厄多，宜行善积德化解', pillar: p.label));
      }
    }
  }

  void _checkYearBranchFixed(List<ShenshaItem> results, BaziChart chart, String yb) {
    final sm = _sangMen[yb], dk = _diaoKe[yb], pm = _piMa[yb];
    for (final p in chart.pillars) {
      if (sm != null && p.branch == sm) {
        _add(results, ShenshaItem(name: '丧门', target: '${p.label}支${p.branch}',
            description: '年支$yb见${p.branch}为丧门（岁前二辰），主孝服、病灾', pillar: p.label));
      }
      if (dk != null && p.branch == dk) {
        _add(results, ShenshaItem(name: '吊客', target: '${p.label}支${p.branch}',
            description: '年支$yb见${p.branch}为吊客（岁后二辰），主吊唁、探病之事', pillar: p.label));
      }
      if (pm != null && p.branch == pm) {
        _add(results, ShenshaItem(name: '披麻', target: '${p.label}支${p.branch}',
            description: '年支$yb见${p.branch}为披麻（岁后三辰），主孝服丧事', pillar: p.label));
      }
    }
  }

  void _checkMonthBranchFixed(List<ShenshaItem> results, BaziChart chart, String mb) {
    final xr = _xueRen[mb], ty = _tianYiYue[mb];
    for (final p in chart.pillars) {
      if (xr != null && p.branch == xr) {
        _add(results, ShenshaItem(name: '血刃', target: '${p.label}支${p.branch}',
            description: '月支$mb见${p.branch}为血刃，主血光外伤，宜注意安全', pillar: p.label));
      }
      if (ty != null && p.branch == ty) {
        _add(results, ShenshaItem(name: '天医', target: '${p.label}支${p.branch}',
            description: '月支$mb见${p.branch}为天医（月建后一位），主与医学有缘、病中得良医', pillar: p.label));
      }
    }
  }

  void _checkPillarDays(List<ShenshaItem> results, BaziChart chart, String dgz) {
    if (_shiLingDays.contains(dgz)) {
      _add(results, ShenshaItem(name: '十灵日', target: '日柱$dgz',
          description: '日柱$dgz为十灵日，主聪明敏锐、直觉力强，有灵性天赋', pillar: '日'));
    }
    if (_baZhuanDays.contains(dgz)) {
      _add(results, ShenshaItem(name: '八专日', target: '日柱$dgz',
          description: '日柱$dgz为八专日，主情感专注但也易有情感纠葛', pillar: '日'));
    }
    if (_liuXiuDays.contains(dgz)) {
      _add(results, ShenshaItem(name: '六秀日', target: '日柱$dgz',
          description: '日柱$dgz为六秀日，主容貌秀丽、才艺出众', pillar: '日'));
    }
    if (_jiuChouDays.contains(dgz)) {
      _add(results, ShenshaItem(name: '九丑日', target: '日柱$dgz',
          description: '日柱$dgz为九丑日，外表美好但内藏隐患，宜守正防邪', pillar: '日'));
    }
  }

  void _checkSiFeiDay(List<ShenshaItem> results, BaziChart chart, String dgz) {
    final mz = chart.month.branch;
    if ((['寅', '卯', '辰'].contains(mz) && ['庚申', '辛酉'].contains(dgz)) ||
        (['巳', '午', '未'].contains(mz) && ['壬子', '癸亥'].contains(dgz)) ||
        (['申', '酉', '戌'].contains(mz) && ['甲寅', '乙卯'].contains(dgz)) ||
        (['亥', '子', '丑'].contains(mz) && ['丙午', '丁巳'].contains(dgz))) {
      _add(results, ShenshaItem(name: '四废日', target: '日柱$dgz',
          description: '日柱$dgz为四废日（春金夏水秋木冬火），主百事不顺、万事荒废', pillar: '日'));
    }
  }

  void _checkZhuan(List<ShenshaItem> results, BaziChart chart, String dgz) {
    final mz = chart.month.branch;
    final spr = ['寅', '卯', '辰'].contains(mz), sum = ['巳', '午', '未'].contains(mz);
    final aut = ['申', '酉', '戌'].contains(mz), win = ['亥', '子', '丑'].contains(mz);
    if (spr && dgz == '乙卯') {
      _add(results, ShenshaItem(name: '天转', target: '日柱$dgz',
          description: '春见乙卯为天转（干支同旺于春），主运势急转', pillar: '日'));
    } else if (spr && dgz == '辛卯') {
      _add(results, ShenshaItem(name: '地转', target: '日柱$dgz',
          description: '春见辛卯为地转（纳音木+地支木专旺），主根基动摇', pillar: '日'));
    } else if (sum && dgz == '丙午') {
      _add(results, ShenshaItem(name: '天转', target: '日柱$dgz',
          description: '夏见丙午为天转（干支同旺于夏），主运势急转', pillar: '日'));
    } else if (sum && dgz == '戊午') {
      _add(results, ShenshaItem(name: '地转', target: '日柱$dgz',
          description: '夏见戊午为地转（纳音火+地支火专旺），主根基动摇', pillar: '日'));
    } else if (aut && dgz == '辛酉') {
      _add(results, ShenshaItem(name: '天转', target: '日柱$dgz',
          description: '秋见辛酉为天转（干支同旺于秋），主运势急转', pillar: '日'));
    } else if (aut && dgz == '癸酉') {
      _add(results, ShenshaItem(name: '地转', target: '日柱$dgz',
          description: '秋见癸酉为地转（纳音金+地支金专旺），主根基动摇', pillar: '日'));
    } else if (win && dgz == '壬子') {
      _add(results, ShenshaItem(name: '天转', target: '日柱$dgz',
          description: '冬见壬子为天转（干支同旺于冬），主运势急转', pillar: '日'));
    } else if (win && dgz == '丙子') {
      _add(results, ShenshaItem(name: '地转', target: '日柱$dgz',
          description: '冬见丙子为地转（纳音水+地支水专旺），主根基动摇', pillar: '日'));
    }
  }

  void _checkSanQi(List<ShenshaItem> results, BaziChart chart) {
    final stems = {chart.year.stem, chart.month.stem, chart.day.stem, chart.hour.stem};
    if (stems.containsAll({'甲', '戊', '庚'})) {
      _add(results, ShenshaItem(name: '三奇贵人', target: '四柱天干',
          description: '四柱甲戊庚全—天上三奇，卓越非凡', pillar: '日'));
    } else if (stems.containsAll({'乙', '丙', '丁'})) {
      _add(results, ShenshaItem(name: '三奇贵人', target: '四柱天干',
          description: '四柱乙丙丁全—地上三奇，才华横溢', pillar: '日'));
    } else if (stems.containsAll({'壬', '癸', '辛'})) {
      _add(results, ShenshaItem(name: '三奇贵人', target: '四柱天干',
          description: '四柱壬癸辛全—人中三奇，智慧超群', pillar: '日'));
    }
  }

  void _checkJinShen(List<ShenshaItem> results, BaziChart chart) {
    final ds = chart.day.stem;
    if (ds != '甲' && ds != '己') return;
    final h = '${chart.hour.stem}${chart.hour.branch}';
    if (h == '癸酉' || h == '己巳' || h == '乙丑') {
      _add(results, ShenshaItem(name: '金神', target: '时柱$h',
          description: '日干$ds见时柱$h为金神，刚毅果断', pillar: '时'));
    }
  }

  void _checkTianLuoDiWang(List<ShenshaItem> results, BaziChart chart) {
    final b = {chart.year.branch, chart.month.branch, chart.day.branch, chart.hour.branch};
    if (b.contains('戌') && b.contains('亥')) {
      _add(results, ShenshaItem(name: '天罗', target: '柱中见戌亥',
          description: '戌亥全见为天罗（火命+男命更重），主困顿难脱', pillar: '年'));
    }
    if (b.contains('辰') && b.contains('巳')) {
      _add(results, ShenshaItem(name: '地网', target: '柱中见辰巳',
          description: '辰巳全见为地网（水土命+女命更重），主羁绊难解', pillar: '年'));
    }
  }

  void _checkTongZi(List<ShenshaItem> results, BaziChart chart) {
    final mz = chart.month.branch;
    final sa = ['寅', '卯', '辰', '申', '酉', '戌'].contains(mz);
    for (final p in [chart.day, chart.hour]) {
      if (sa && (p.branch == '寅' || p.branch == '子')) {
        _add(results, ShenshaItem(name: '童子', target: '${p.label}支${p.branch}',
            description: '春秋月见${p.branch}为童子，主有仙缘', pillar: p.label));
      }
      if (!sa && (p.branch == '卯' || p.branch == '未' || p.branch == '辰')) {
        _add(results, ShenshaItem(name: '童子', target: '${p.label}支${p.branch}',
            description: '冬夏月见${p.branch}为童子，主有仙缘', pillar: p.label));
      }
    }
  }
}