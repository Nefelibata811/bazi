import '../../domain/entities/bazi_chart.dart';
import '../../domain/entities/shensha_item.dart';
import '../../domain/services/shensha_calculator.dart';

class StubShenshaCalculator implements ShenshaCalculator {
  @override
  Future<List<ShenshaItem>> calculate(BaziChart chart) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));

    return const [
      ShenshaItem(
        name: '天乙贵人',
        target: '年支辰',
        description: '主逢凶化吉、得人扶助，仍需配合格局喜忌判断。',
      ),
      ShenshaItem(
        name: '华盖',
        target: '日支未',
        description: '偏向审美、独处、学术或玄学气质。',
      ),
      ShenshaItem(
        name: '桃花',
        target: '时支酉',
        description: '主形象与人缘，吉凶须结合十神与组合。',
      ),
    ];
  }
}
