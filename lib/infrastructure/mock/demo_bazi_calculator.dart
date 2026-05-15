import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/bazi_request.dart';
import '../../domain/entities/hidden_stem.dart';
import '../../domain/entities/pillar.dart';
import '../../domain/services/bazi_calculator.dart';

class DemoBaziCalculator implements BaziCalculator {
  @override
  Future<BaziChart> calculate(BaziRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    return const BaziChart(
      dayMaster: '癸',
      year: Pillar(
        label: '年柱',
        stem: '甲',
        branch: '辰',
        tenGod: '伤官',
        hiddenStems: [
          HiddenStem(stem: '戊', tenGod: '正官'),
          HiddenStem(stem: '乙', tenGod: '食神'),
          HiddenStem(stem: '癸', tenGod: '比肩'),
        ],
        naYin: '覆灯火',
        growthPhase: '养',
      ),
      month: Pillar(
        label: '月柱',
        stem: '丙',
        branch: '寅',
        tenGod: '偏财',
        hiddenStems: [
          HiddenStem(stem: '甲', tenGod: '伤官'),
          HiddenStem(stem: '丙', tenGod: '偏财'),
          HiddenStem(stem: '戊', tenGod: '正官'),
        ],
        naYin: '炉中火',
        growthPhase: '沐浴',
      ),
      day: Pillar(
        label: '日柱',
        stem: '癸',
        branch: '未',
        tenGod: '日主',
        hiddenStems: [
          HiddenStem(stem: '己', tenGod: '七杀'),
          HiddenStem(stem: '丁', tenGod: '正财'),
          HiddenStem(stem: '乙', tenGod: '食神'),
        ],
        naYin: '杨柳木',
        growthPhase: '墓',
      ),
      hour: Pillar(
        label: '时柱',
        stem: '辛',
        branch: '酉',
        tenGod: '偏印',
        hiddenStems: [
          HiddenStem(stem: '辛', tenGod: '偏印'),
        ],
        naYin: '石榴木',
        growthPhase: '病',
      ),
    );
  }
}
