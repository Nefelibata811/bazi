// 表格式四柱排盘 UI：左侧行标签 + 年/月/日/时四列（主星、干支、藏干、副星、星运、自坐、神煞）。

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../app/theme/five_element_colors.dart';
import 'five_element_char.dart';
import '../../../../domain/entities/bazi_chart.dart';
import '../../../../domain/entities/pillar.dart';
import '../../../../domain/entities/ren_yuan_si_ling.dart';
import '../../../../domain/entities/shensha_item.dart';
import '../../../../domain/services/bazi_rule_engine.dart';

const _ruleEngine = BaziRuleEngine();

/// 表格式四柱排盘：左侧行标签 + 年/月/日/时四列，类似传统排盘软件。
class BaziCoreChartCard extends StatelessWidget {
  const BaziCoreChartCard({
    super.key,
    required this.chart,
    this.shenshaItems = const [],
    this.renYuanSiLing,
  });

  final BaziChart chart;
  final List<ShenshaItem> shenshaItems;
  final RenYuanSiLing? renYuanSiLing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pillars = chart.pillars;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Text('四柱排盘', style: textTheme.titleLarge),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cinnabar.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '日主 ${chart.dayMaster}',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.cinnabar,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: const FiveElementLegend(),
          ),
          _ChartTableHeader(pillars: pillars),
          _ChartTableRow(
            stripe: true,
            label: '主星',
            cells: pillars
                .map((p) => _TableText(p.tenGod, bold: true))
                .toList(),
          ),
          _ChartTableRow(
            label: '天干',
            minHeight: 58,
            cells: pillars
                .map(
                  (p) => FiveElementChar(
                    text: p.stem,
                    color: FiveElementColors.byStem(p.stem),
                  ),
                )
                .toList(),
          ),
          _ChartTableRow(
            stripe: true,
            label: '地支',
            minHeight: 58,
            cells: pillars
                .map(
                  (p) => FiveElementChar(
                    text: p.branch,
                    color: FiveElementColors.byBranch(p.branch),
                  ),
                )
                .toList(),
          ),
          _ChartTableRow(
            label: '藏干',
            cells: pillars
                .map((p) => _HiddenStemCell(pillar: p))
                .toList(),
          ),
          _ChartTableRow(
            stripe: true,
            label: '副星',
            cells: pillars
                .map(
                  (p) => _StackedLines(
                    p.hiddenStems.map((h) => h.tenGod).toList(),
                    muted: true,
                  ),
                )
                .toList(),
          ),
          _ChartTableRow(
            label: '纳音',
            cells: pillars.map((p) => _TableText(p.naYin)).toList(),
          ),
          _ChartTableRow(
            stripe: true,
            label: '星运',
            cells: pillars.map((p) => _TableText(p.growthPhase)).toList(),
          ),
          _ChartTableRow(
            label: '自坐',
            cells: pillars
                .map((p) => _TableText(_seatGrowthPhase(p)))
                .toList(),
          ),
          if (pillars.any((p) => p.xunKong.isNotEmpty))
            _ChartTableRow(
              stripe: true,
              label: '空亡',
              cells: pillars
                  .map(
                    (p) => _TableText(
                      p.xunKong.isEmpty ? '—' : p.xunKong,
                      muted: p.xunKong.isEmpty,
                    ),
                  )
                  .toList(),
            ),
          if (renYuanSiLing?.summary != null &&
              renYuanSiLing!.summary.isNotEmpty)
            _ChartTableRow(
              stripe: false,
              label: '司令',
              cells: [
                const _TableText('—', muted: true),
                _TableText(renYuanSiLing!.summary, color: AppColors.gold),
                const _TableText('—', muted: true),
                const _TableText('—', muted: true),
              ],
            ),
          if (shenshaItems.isNotEmpty)
            _ChartTableRow(
              stripe: true,
              label: '神煞',
              cells: pillars
                  .map(
                    (p) => _ShenshaCell(
                      items: shenshaItems
                          .where((s) => s.pillar == p.label)
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ChartTableHeader extends StatelessWidget {
  const _ChartTableHeader({required this.pillars});

  final List<Pillar> pillars;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink.withValues(alpha: 0.92),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          const SizedBox(width: _ChartTableRow.labelWidth),
          for (final p in pillars)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.label,
                    textAlign: TextAlign.center,
                    style: BaziChartTextStyles.headerPillar(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${p.stem}${p.branch}',
                    textAlign: TextAlign.center,
                    style: BaziChartTextStyles.headerGanZhi(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartTableRow extends StatelessWidget {
  const _ChartTableRow({
    required this.label,
    required this.cells,
    this.stripe = false,
    this.minHeight = 40,
  });

  static const labelWidth = 56.0;

  final String label;
  final List<Widget> cells;
  final bool stripe;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      color: stripe ? AppColors.rice.withValues(alpha: 0.65) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(label, style: BaziChartTextStyles.rowLabel()),
            ),
          ),
          for (final cell in cells) Expanded(child: cell),
        ],
      ),
    );
  }
}

class _HiddenStemCell extends StatelessWidget {
  const _HiddenStemCell({required this.pillar});

  final Pillar pillar;

  @override
  Widget build(BuildContext context) {
    if (pillar.hiddenStems.isEmpty) {
      return const _TableText('—', muted: true);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final h in pillar.hiddenStems)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: FiveElementChar(
              text: _ruleEngine.stemElementLabel(h.stem),
              color: FiveElementColors.byStem(h.stem),
              large: false,
            ),
          ),
      ],
    );
  }
}

class _TableText extends StatelessWidget {
  const _TableText(
    this.text, {
    this.bold = false,
    this.muted = false,
    this.color,
  });

  final String text;
  final bool bold;
  final bool muted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: muted
          ? BaziChartTextStyles.cellMuted()
          : BaziChartTextStyles.cell(
              bold: bold,
              color: color ?? AppColors.ink,
            ),
    );
  }
}

class _StackedLines extends StatelessWidget {
  const _StackedLines(this.lines, {this.muted = false});

  final List<String> lines;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const _TableText('—', muted: true);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          Text(
            line,
            textAlign: TextAlign.center,
            style: BaziChartTextStyles.stacked(muted: muted),
          ),
      ],
    );
  }
}

class _ShenshaCell extends StatelessWidget {
  const _ShenshaCell({required this.items});

  final List<ShenshaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _TableText('—', muted: true);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: GestureDetector(
              onTap: () => _showShenshaDetail(context, item),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                style: BaziChartTextStyles.shensha(
                  color: _shenshaColor(item.name),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _seatGrowthPhase(Pillar pillar) {
  if (pillar.seatGrowthPhase.isNotEmpty) return pillar.seatGrowthPhase;
  return _ruleEngine.growthPhaseFor(
    dayMasterStem: pillar.stem,
    branch: pillar.branch,
  );
}

Color _shenshaColor(String name) {
  const auspicious = {
    '天乙贵人', '太极贵人', '福星贵人', '天德贵人', '月德贵人',
    '文昌', '学堂', '词馆', '禄神', '金舆', '国印贵人',
    '天厨贵人', '德秀贵人', '天赦日', '天医',
    '红鸾', '天喜', '将星', '三奇贵人', '十灵日', '六秀日',
  };
  const inauspicious = {
    '亡神', '劫煞', '灾煞', '羊刃', '飞刃',
    '孤辰', '寡宿', '魁罡', '十恶大败', '孤鸾煞', '阴错阳差',
    '丧门', '吊客', '披麻', '血刃',
    '红艳煞', '流霞', '四废日', '八专日', '九丑日',
    '天转', '地转', '天罗', '地网',
  };
  if (auspicious.contains(name)) return AppColors.gold;
  if (inauspicious.contains(name)) return AppColors.cinnabar;
  return AppColors.deepGray;
}

String _shenshaCategory(String name) {
  const auspicious = {
    '天乙贵人', '太极贵人', '福星贵人', '天德贵人', '月德贵人',
    '文昌', '学堂', '词馆', '禄神', '金舆', '国印贵人',
    '天厨贵人', '德秀贵人', '天赦日', '天医',
    '红鸾', '天喜', '将星', '三奇贵人', '十灵日', '六秀日',
  };
  const inauspicious = {
    '亡神', '劫煞', '灾煞', '羊刃', '飞刃',
    '孤辰', '寡宿', '魁罡', '十恶大败', '孤鸾煞', '阴错阳差',
    '丧门', '吊客', '披麻', '血刃',
    '红艳煞', '流霞', '四废日', '八专日', '九丑日',
    '天转', '地转', '天罗', '地网',
  };
  if (auspicious.contains(name)) return '吉';
  if (inauspicious.contains(name)) return '凶';
  return '平';
}

void _showShenshaDetail(BuildContext context, ShenshaItem item) {
  final category = _shenshaCategory(item.name);
  final color = _shenshaColor(item.name);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.target,
            style: Theme.of(ctx)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
