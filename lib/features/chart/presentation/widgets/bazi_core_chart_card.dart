// 文件：八字核心命盘card
//
// UI 组件：可复用的界面片段。
// 路径：`lib/features/chart/presentation/widgets/bazi_core_chart_card.dart`。
//
// 表格式四柱排盘 UI：左侧行标签 + 年/月/日/时四列（主星、干支、藏干、副星、星运、自坐、神煞）。

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/five_element_colors.dart';
import 'bazi_chart_table_widgets.dart';
import 'five_element_char.dart';
import '../../../../domain/entities/bazi_chart.dart';
import '../../../../domain/entities/ren_yuan_si_ling.dart';
import '../../../../domain/entities/shensha_item.dart';

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

  // 构建界面布局。

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
          BaziChartTableHeader(pillars: pillars),
          BaziChartTableRow(
            stripe: true,
            label: '主星',
            cells: pillars
                .map((p) => BaziChartTableText(p.tenGod, bold: true))
                .toList(),
          ),
          BaziChartTableRow(
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
          BaziChartTableRow(
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
          BaziChartTableRow(
            label: '藏干',
            cells: pillars
                .map((p) => BaziChartHiddenStemCell(pillar: p))
                .toList(),
          ),
          BaziChartTableRow(
            stripe: true,
            label: '副星',
            cells: pillars
                .map(
                  (p) => BaziChartStackedLines(
                    p.hiddenStems.map((h) => h.tenGod).toList(),
                    muted: true,
                  ),
                )
                .toList(),
          ),
          BaziChartTableRow(
            label: '纳音',
            cells: pillars.map((p) => BaziChartTableText(p.naYin)).toList(),
          ),
          BaziChartTableRow(
            stripe: true,
            label: '星运',
            cells: pillars.map((p) => BaziChartTableText(p.growthPhase)).toList(),
          ),
          BaziChartTableRow(
            label: '自坐',
            cells: pillars
                .map((p) => BaziChartTableText(seatGrowthPhaseFor(p)))
                .toList(),
          ),
          if (pillars.any((p) => p.xunKong.isNotEmpty))
            BaziChartTableRow(
              stripe: true,
              label: '空亡',
              cells: pillars
                  .map(
                    (p) => BaziChartTableText(
                      p.xunKong.isEmpty ? '—' : p.xunKong,
                      muted: p.xunKong.isEmpty,
                    ),
                  )
                  .toList(),
            ),
          if (renYuanSiLing?.summary != null &&
              renYuanSiLing!.summary.isNotEmpty)
            BaziChartTableRow(
              stripe: false,
              label: '司令',
              cells: [
                const BaziChartTableText('—', muted: true),
                BaziChartTableText(renYuanSiLing!.summary, color: AppColors.gold),
                const BaziChartTableText('—', muted: true),
                const BaziChartTableText('—', muted: true),
              ],
            ),
          if (shenshaItems.isNotEmpty)
            BaziChartTableRow(
              stripe: true,
              label: '神煞',
              cells: pillars
                  .map(
                    (p) => BaziChartShenshaCell(
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
