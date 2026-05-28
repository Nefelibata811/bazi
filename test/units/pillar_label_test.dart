// 文件：单元测试 — 柱标签
//
// 验证 柱标签 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/domain/entities/pillar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prodDay = Pillar(
    label: '日',
    stem: '癸',
    branch: '酉',
    tenGod: '日主',
    hiddenStems: [],
    naYin: '',
    growthPhase: '',
  );
  const testDay = Pillar(
    label: '日柱',
    stem: '癸',
    branch: '酉',
    tenGod: '日主',
    hiddenStems: [],
    naYin: '',
    growthPhase: '',
  );

  test('生产与测试日柱标签均识别为日柱', () {
    expect(prodDay.isDayColumn, isTrue);
    expect(testDay.isDayColumn, isTrue);
    expect(prodDay.isCoreFourColumn, isTrue);
  });

  test('辅宫标签不属于本命四柱', () {
    const ming = Pillar(
      label: '命宫',
      stem: '己',
      branch: '丑',
      tenGod: '七杀',
      hiddenStems: [],
      naYin: '',
      growthPhase: '',
    );
    expect(ming.isCoreFourColumn, isFalse);
    expect(ming.isDayColumn, isFalse);
  });
}
