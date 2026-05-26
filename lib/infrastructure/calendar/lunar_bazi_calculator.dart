// 四柱排盘实现：基于 lunar 包的 EightChar，组装 BaziChart 与称骨等。
// 规则补充见 BaziRuleEngine；请求入口 LunarEightCharFactory。
import 'package:lunar/lunar.dart';

import '../../../domain/entities/bazi_chart.dart';
import '../../../domain/entities/bazi_report.dart';
import '../../../domain/entities/bazi_request.dart';
import '../../../domain/entities/pillar.dart';
import '../../../domain/services/bazi_calculator.dart';
import '../../../domain/services/bazi_rule_engine.dart';
import 'lunar_eight_char_factory.dart';

class LunarBaziCalculator implements BaziCalculator {
  const LunarBaziCalculator({
    required BaziRuleEngine ruleEngine,
  }) : _ruleEngine = ruleEngine;

  final BaziRuleEngine _ruleEngine;

  @override
  Future<BaziChart> calculate(BaziRequest request) async {
    final ec = LunarEightCharFactory.eightCharFromRequest(request);

    final dayGan = ec.getDayGan();

    return BaziChart(
      dayMaster: dayGan,
      year: _pillar(ec, '年', dayGan, ec.getYearGan(), ec.getYearZhi(),
          ec.getYearNaYin(), ec.getYearShiShenGan(), ec.getYearDiShi(),
          xunKong: ec.getYearXunKong()),
      month: _pillar(ec, '月', dayGan, ec.getMonthGan(), ec.getMonthZhi(),
          ec.getMonthNaYin(), ec.getMonthShiShenGan(), ec.getMonthDiShi(),
          xunKong: ec.getMonthXunKong()),
      day: _pillar(ec, '日', dayGan, ec.getDayGan(), ec.getDayZhi(),
          ec.getDayNaYin(), '日主', ec.getDayDiShi(),
          xunKong: ec.getDayXunKong()),
      hour: _pillar(ec, '时', dayGan, ec.getTimeGan(), ec.getTimeZhi(),
          ec.getTimeNaYin(), ec.getTimeShiShenGan(), ec.getTimeDiShi(),
          xunKong: ec.getTimeXunKong()),
      extraPillars: _extraPillars(ec, dayGan),
    );
  }

  List<Pillar> _extraPillars(EightChar ec, String dayGan) {
    return [
      _extraPillar(ec, dayGan, '命宫', ec.getMingGong(), ec.getMingGongNaYin()),
      _extraPillar(ec, dayGan, '身宫', ec.getShenGong(), ec.getShenGongNaYin()),
      _extraPillar(ec, dayGan, '胎元', ec.getTaiYuan(), ec.getTaiYuanNaYin()),
      _extraPillar(ec, dayGan, '胎息', ec.getTaiXi(), ec.getTaiXiNaYin()),
    ];
  }

  Pillar _extraPillar(
    EightChar ec,
    String dayGan,
    String label,
    String ganZhi,
    String naYin,
  ) {
    final stem = ganZhi.substring(0, 1);
    final branch = ganZhi.substring(1, 2);
    return Pillar(
      label: label,
      stem: stem,
      branch: branch,
      tenGod: _ruleEngine.tenGodFor(dayMasterStem: dayGan, targetStem: stem),
      hiddenStems: _ruleEngine.hiddenStemsFor(
        dayMasterStem: dayGan,
        branch: branch,
      ),
      naYin: naYin,
      growthPhase: _ruleEngine.growthPhaseFor(
        dayMasterStem: dayGan,
        branch: branch,
      ),
      seatGrowthPhase: _ruleEngine.growthPhaseFor(
        dayMasterStem: stem,
        branch: branch,
      ),
    );
  }

  BoneWeight? calculateBoneWeight(BaziRequest request) {
    try {
      final lunar = LunarEightCharFactory.lunarFromRequest(request);

      final yearGanZhi = '${lunar.getYearGan()}${lunar.getYearZhi()}';
      final yearW = _yearWeights[yearGanZhi];
      if (yearW == null) return null;

      final lunarMonth = lunar.getMonth().abs();
      final monthW = _monthWeights[lunarMonth];
      if (monthW == null) return null;

      final dayW = _dayWeights[lunar.getDay()];
      if (dayW == null) return null;

      final shichen = _shichenIndex(lunar.getHour());
      final timeW = _timeWeights[shichen];
      if (timeW == null) return null;

      final total = yearW + monthW + dayW + timeW;
      final totalStr = total.toStringAsFixed(1);
      final maleComment = _maleComments[totalStr];
      final femaleComment = _femaleComments[totalStr];

      if (maleComment == null || femaleComment == null) return null;

      return BoneWeight(
        totalWeight: total,
        maleComment: maleComment,
        femaleComment: femaleComment,
      );
    } catch (_) {
      return null;
    }
  }

  Pillar _pillar(
    EightChar ec,
    String label,
    String dayGan,
    String stem,
    String branch,
    String naYin,
    String tenGod,
    String growthPhase, {
    String xunKong = '',
  }) {
    final hiddenStems =
        _ruleEngine.hiddenStemsFor(dayMasterStem: dayGan, branch: branch);

    return Pillar(
      label: label,
      stem: stem,
      branch: branch,
      tenGod: tenGod,
      hiddenStems: hiddenStems,
      naYin: naYin,
      growthPhase: growthPhase,
      seatGrowthPhase: _ruleEngine.growthPhaseFor(
        dayMasterStem: stem,
        branch: branch,
      ),
      xunKong: xunKong,
    );
  }

  static int _shichenIndex(int hour) {
    if (hour >= 23 || hour < 1) return 0;
    if (hour >= 1 && hour < 3) return 1;
    if (hour >= 3 && hour < 5) return 2;
    if (hour >= 5 && hour < 7) return 3;
    if (hour >= 7 && hour < 9) return 4;
    if (hour >= 9 && hour < 11) return 5;
    if (hour >= 11 && hour < 13) return 6;
    if (hour >= 13 && hour < 15) return 7;
    if (hour >= 15 && hour < 17) return 8;
    if (hour >= 17 && hour < 19) return 9;
    if (hour >= 19 && hour < 21) return 10;
    return 11;
  }

  static const _timeWeights = <int, double>{
    0: 1.6, 1: 0.6, 2: 0.7, 3: 1.0, 4: 0.9, 5: 1.6,
    6: 1.0, 7: 0.8, 8: 0.8, 9: 0.9, 10: 0.6, 11: 0.6,
  };

  static const _monthWeights = <int, double>{
    1: 0.6, 2: 0.7, 3: 1.8, 4: 0.9, 5: 0.5, 6: 1.6,
    7: 0.9, 8: 1.5, 9: 1.8, 10: 0.8, 11: 0.9, 12: 0.5,
  };

  static const _dayWeights = <int, double>{
    1: 0.5, 2: 1.0, 3: 0.8, 4: 1.5, 5: 1.6, 6: 1.5,
    7: 0.8, 8: 1.6, 9: 0.8, 10: 1.6, 11: 0.9, 12: 1.7,
    13: 0.8, 14: 1.7, 15: 1.0, 16: 0.8, 17: 0.9, 18: 1.8,
    19: 0.5, 20: 1.5, 21: 1.0, 22: 0.9, 23: 0.8, 24: 0.9,
    25: 1.5, 26: 1.8, 27: 0.7, 28: 0.8, 29: 1.6, 30: 0.6,
  };

  static const _yearWeights = <String, double>{
    '甲子': 1.2, '乙丑': 0.9, '丙寅': 0.6, '丁卯': 0.7,
    '戊辰': 1.2, '己巳': 0.5, '庚午': 0.9, '辛未': 0.8,
    '壬申': 0.7, '癸酉': 0.8, '甲戌': 1.5, '乙亥': 0.9,
    '丙子': 1.6, '丁丑': 0.8, '戊寅': 0.8, '己卯': 1.9,
    '庚辰': 1.2, '辛巳': 0.6, '壬午': 0.8, '癸未': 0.7,
    '甲申': 0.5, '乙酉': 1.5, '丙戌': 0.6, '丁亥': 1.6,
    '戊子': 1.5, '己丑': 0.7, '庚寅': 0.9, '辛卯': 1.2,
    '壬辰': 1.0, '癸巳': 0.7, '甲午': 1.5, '乙未': 0.6,
    '丙申': 0.5, '丁酉': 1.4, '戊戌': 1.4, '己亥': 0.9,
    '庚子': 0.7, '辛丑': 0.7, '壬寅': 0.9, '癸卯': 1.2,
    '甲辰': 0.8, '乙巳': 0.7, '丙午': 1.3, '丁未': 0.5,
    '戊申': 1.4, '己酉': 0.5, '庚戌': 0.9, '辛亥': 1.7,
    '壬子': 0.5, '癸丑': 0.7, '甲寅': 1.2, '乙卯': 0.8,
    '丙辰': 0.8, '丁巳': 0.6, '戊午': 1.9, '己未': 0.6,
    '庚申': 0.8, '辛酉': 1.6, '壬戌': 1.0, '癸亥': 0.7,
  };

  static const _maleComments = <String, String>{
    '2.1': '短命非业谓大凶，平生灾难事重重。凶祸频临陷逆境，终世困苦事不成。',
    '2.2': '身寒骨冷苦伶仃，此命推来行乞人。劳劳碌碌无度日，终年打拱过平生。',
    '2.3': '此命推来骨格轻，求谋做事事难成。妻儿兄弟实难靠，外出他乡做散人。',
    '2.4': '此命推来福禄无，门庭困苦总难荣。六亲骨肉皆无靠，流浪他乡作老翁。',
    '2.5': '此命推来祖业微，门庭营度似稀奇。六亲骨肉如冰炭，一世勤劳自把持。',
    '2.6': '平生衣禄苦中求，独自营谋事不休。离祖出门宜早计，晚来衣禄自无休。',
    '2.7': '一生作事少商量，难靠祖宗作主张。独马单枪空做去，早年晚岁总无长。',
    '2.8': '一生行事似飘蓬，祖宗产业在梦中。若不过房改名姓，也当移徒二三通。',
    '2.9': '初年运限未曾亨，纵有功名在后成。须过四旬才可立，移居改姓始为良。',
    '3.0': '劳劳碌碌苦中求，东奔西走何日休。若使终身勤与俭，老来稍可免忧愁。',
    '3.1': '忙忙碌碌苦中求，何日云开见日头。难得祖基家可立，中年衣食渐无忧。',
    '3.2': '初年运蹇事难谋，渐有财源如水流。到得中年衣食旺，那时名利一齐收。',
    '3.3': '早年做事事难成，百年勤劳枉费心。半世自如流水去，后来运到始得金。',
    '3.4': '此命福气果如何，僧道门中衣禄多。离祖出家方为妙，朝晚拜佛念弥陀。',
    '3.5': '生平福量不周全，祖业根基觉少传。营事生涯宜守旧，时来衣食胜从前。',
    '3.6': '不须劳碌过平生，独自成家福不轻。早有福星常照命，任君行去百般成。',
    '3.7': '此命般般事不成，弟兄少力自孤行。虽然祖业须微有，来得明时去不明。',
    '3.8': '一身骨肉最清高，早入簧门姓氏标。待到年将三十六，蓝衫脱去换红袍。',
    '3.9': '此命终身运不通，劳劳作事尽皆空。苦心竭力成家计，到得那时在梦中。',
    '4.0': '平生衣禄是绵长，件件心中自主张。前面风霜多受过，后来必定享安康。',
    '4.1': '此命推来自不同，为人能干异凡庸。中年还有逍遥福，不比前时运来通。',
    '4.2': '得宽怀处且宽怀，何用双眉皱不开。若使中年命运济，那时名利一起来。',
    '4.3': '为人心性最聪明，做事轩昂近贵人。衣禄一生天注定，不须劳碌是丰亨。',
    '4.4': '万事由天莫苦求，须知福碌赖人修。当年财帛难如意，晚景欣然便不优。',
    '4.5': '名利推求竟若何，前番辛苦后奔波。命中难养男和女，骨肉扶持也不多。',
    '4.6': '东西南北尽皆通，出姓移居更觉隆。衣禄无穷无数定，中年晚景一般同。',
    '4.7': '此命推求旺末年，妻荣子贵自怡然。平生原有滔滔福，可卜财源若水泉。',
    '4.8': '初年运道未曾通，几许蹉跎命亦穷。兄弟六亲无依靠，一生事业晚来整。',
    '4.9': '此命推来福不轻，自成自立显门庭。从来富贵人钦敬，使婢差奴过一生。',
    '5.0': '为利为名终日劳，中年福禄也多遭。老来自有财星照，不比前番目下高。',
    '5.1': '一世荣华事事通，不须劳碌自亨通。弟兄叔侄皆如意，家业成时福禄宏。',
    '5.2': '一世亨通事事能，不须劳苦自然宁。宗族有光欣喜甚，家产丰盈自称心。',
    '5.3': '此格推来福泽宏，兴家立业在其中。一生衣食安排定，却是人间一福翁。',
    '5.4': '此格详采福泽宏，诗书满腹看功成。丰衣足食多安稳，正是人间有福人。',
    '5.5': '策马扬鞭争名利，少年作事费筹论。一朝福禄源源至，富贵荣华显六亲。',
    '5.6': '此格推来礼义通，一身福禄用无穷。甜酸苦辣皆尝过，滚滚财源盈而丰。',
    '5.7': '福禄丰盈万事全，一身荣耀乐天年。名扬威震人争羡，此世逍遥宛似仙。',
    '5.8': '平生衣食自然来，名利双全富贵偕。金榜题名登甲第，紫袍玉带走金阶。',
    '5.9': '细推此格秀而清，必定才高学业成。甲第之中应有分，扬鞭走马显威荣。',
    '6.0': '一朝金榜快题名，显祖荣宗大器成。衣禄定然无欠缺，田园财帛更丰盈。',
    '6.1': '不作朝中金榜客，定为世上大财翁。聪明天付经书熟，名显高褂自是荣。',
    '6.2': '此命生来福不穷，读书必定显亲宗。紫衣玉带为卿相，富贵荣华孰与同。',
    '6.3': '命主为官福禄长，得来富贵实非常。名题雁塔传金榜，大显门庭天下扬。',
    '6.4': '此格威权不可当，紫袍金带尘高堂。荣华富贵谁能及，万古留名姓氏扬。',
    '6.5': '细推此命福非轻，富贵荣华孰与争。定国安邦人极品，威声显赫震寰瀛。',
    '6.6': '此格人间一福人，堆金积玉满堂春。从来富贵有天定，金榜题名更显亲。',
    '6.7': '此命生来福自宏，田园家业最高隆。平生衣禄盈丰足，一路荣华万事通。',
    '6.8': '富贵由天莫苦求，万金家计不须谋。如今不比前翻事，祖业根基万古留。',
    '6.9': '君是人间衣禄星，一生富贵众人钦。总然衣禄由天定，安享荣华过一生。',
    '7.0': '此命推来福不轻，何须愁虑苦劳心。荣华富贵已天定，正笏垂绅拜紫宸。',
    '7.1': '此命生成大不同，公侯卿相在其中。一生自有逍遥福，富贵荣华极品隆。',
    '7.2': '此命推来天下隆，必定人间一主公。富贵荣华数不尽，定为乾坤一蛟龙。',
  };

  static const _femaleComments = <String, String>{
    '2.1': '短命非业谓大凶，平生灾难事重重。凶祸频临陷逆境，终世困苦事不成。',
    '2.2': '此命推来事艰难，奔波劳碌苦不堪。操心家务是非起，结发夫妻见面难。',
    '2.3': '此命推来骨格轻，求谋做事事难成。主家操劳心力瘁，清冷门庭度一生。',
    '2.4': '此命推来福禄无，门庭困苦口难糊。六亲骨肉皆无靠，孤灯独守晚年枯。',
    '2.5': '此命推来祖业微，门庭冷落运气稀。一生劳苦身多病，比肩操劳自把持。',
    '2.6': '平生衣禄苦中求，女命持家事不休。终日劳心兼费口，晚年方得少忧愁。',
    '2.7': '女命推来性情柔，凡事有主自运筹。室家和美得人敬，中晚之时福自收。',
    '2.8': '女命生来性最良，一生温和敬夫郎。命中应有儿孙福，晚景安然福寿长。',
    '2.9': '此命推来甚聪明，女命逢之百事精。自有福星常拱照，一生衣禄享安平。',
    '3.0': '女命推来事可伤，命中无有儿郎当。若得赘婿承宗嗣，好比燕山窦十郎。',
    '3.1': '早年行运在忙忙，劳碌奔波苦自尝。女命为人多主导，持家辛苦费心肠。',
    '3.2': '时逢吉神在运中，纵有凶处不为凶。女命推来操持好，夫荣子贵受褒封。',
    '3.3': '女命推来心最善，待人接物甚周详。一生福禄天公赐，晚景丰隆更吉祥。',
    '3.4': '凤鸣歧山闻四方，女命逢之大吉昌。走失夫君音信有，晚年衣禄财盈箱。',
    '3.5': '女命推来运未亨，劳碌奔波苦一生。操心家务心难静，晚年稍得免忧惊。',
    '3.6': '此命推来性最良，一生行善敬神堂。自有福星常照命，儿女成行福泽长。',
    '3.7': '女命生来好容仪，性情温良擅言辞。持家立业皆称意，晚景丰荣子满枝。',
    '3.8': '女命推来貌如花，聪明伶俐受人夸。婚姻合和夫荣贵，衣禄丰盈享岁华。',
    '3.9': '此命推来运不通，女命勤劳当作空。尽心竭力成家计，到得那时在梦中。',
    '4.0': '女命推来福不轻，一生勤俭操持精。持家有道人称羡，晚景荣华福自盈。',
    '4.1': '此命推来是不同，女命逢之禄万钟。衣禄丰盈无欠缺，晚岁荣华更兴隆。',
    '4.2': '女命推来心最慈，待人接物有施为。一生福禄天公赐，夫荣子贵耀门楣。',
    '4.3': '女命推来重信义，心性温和最善慈。内助家声名早著，荣华富贵岁时滋。',
    '4.4': '夜雨无情惊醒梦，西风有意折飞花。女命推来多厄难，从此泥潭度岁华。',
    '4.5': '女命推来福不轻，自强自立显门庭。持家创业皆如意，富贵荣华享太平。',
    '4.6': '女命推来性情灵，当家操持最精明。待人和气人钦敬，晚景荣华福满庭。',
    '4.7': '此命推来性最刚，女命逢之立主张。持家有道人称羡，夫荣子贵姓名香。',
    '4.8': '初年运道未曾通，几许蹉跎命亦穷。手足六亲难得力，一生事业晚来隆。',
    '4.9': '此命推来福不轻，女命逢之事事能。夫荣子贵家兴旺，一路荣华到百龄。',
    '5.0': '女命推来福非轻，八面玲珑事事精。夫荣子贵高官做，马前喝道状元行。',
    '5.1': '此命推来品格清，讲信修仁最真诚。持家节俭人称羡，晚景荣华福寿增。',
    '5.2': '女命推来心最良，一生行善敬神堂。自有福星常照命，儿女成行福泽长。',
    '5.3': '此命推来福泽宏，兴家立业在其中。一生衣禄天公定，正是人间福命翁。',
    '5.4': '此格详采福泽宏，诗书满腹看功成。丰衣足食多安稳，正是人间有福人。',
    '5.5': '策马扬鞭争名利，女命逢之事有成。一朝福禄源源至，富贵荣华显门庭。',
    '5.6': '此格推来礼义通，女命和顺万事通。甜酸苦辣皆尝过，滚滚财源盈而丰。',
    '5.7': '福禄丰盈万事全，一身荣耀显门闾。名扬威震人争羡，此世逍遥福自余。',
    '5.8': '女命推来貌若仙，聪明伶俐压婵娟。夫荣子贵登金榜，福寿双全享百年。',
    '5.9': '细推此格秀而清，女命逢之学业成。甲第之中应有分，紫袍玉带耀门庭。',
    '6.0': '一朝金榜快题名，女命逢之也显荣。衣禄定然无欠缺，田园财帛更丰盈。',
    '6.1': '不作凤冠并霞帔，也是人间富贵花。聪明伶俐人多羡，福寿绵长享岁华。',
    '6.2': '此命生来福不穷，女命逢之主贵荣。紫衣玉带为诰命，富贵荣华孰与同。',
    '6.3': '命主为官福禄长，女命逢之贵异常。名题金榜传天下，大显门庭姓字香。',
    '6.4': '此格威权不可当，紫袍金带坐高堂。荣华富贵谁能及，万古留名姓氏扬。',
    '6.5': '细推此命福非轻，富贵荣华孰与争。定国安邦人极品，威声显赫震寰瀛。',
    '6.6': '此格人间一福人，堆金积玉满堂春。从来富贵有天定，金榜题名更显亲。',
    '6.7': '此命生来福自宏，田园家业最高隆。平生衣禄盈丰足，一路荣华万事通。',
    '6.8': '富贵由天莫苦求，万金家计不须谋。如今不比前翻事，祖业根基万古留。',
    '6.9': '君是人间衣禄星，一生康宁享遐龄。女命逢之多吉庆，夫荣子贵振家声。',
    '7.0': '此命推来福不轻，何须愁虑苦劳心。荣华富贵已天定，正笏垂绅拜紫宸。',
    '7.1': '此命生成大不同，公侯卿相在其中。一生自有逍遥福，富贵荣华极品隆。',
    '7.2': '此命推来天下隆，必定人间一主公。富贵荣华数不尽，定为乾坤一蛟龙。',
  };
}
