import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../domain/entities/pillar.dart';
import '../../../../domain/entities/shensha_item.dart';
import '../../../../domain/services/bazi_rule_engine.dart';
import 'five_element_char.dart';
import '../../../../app/theme/five_element_colors.dart';

const baziChartRuleEngine = BaziRuleEngine();

class BaziChartTableHeader extends StatelessWidget {
  const BaziChartTableHeader({super.key, required this.pillars});

  final List<Pillar> pillars;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink.withValues(alpha: 0.92),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          const SizedBox(width: BaziChartTableRow.labelWidth),
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

class BaziChartTableRow extends StatelessWidget {
  const BaziChartTableRow({
    super.key,
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

class BaziChartTableText extends StatelessWidget {
  const BaziChartTableText(
    this.text, {
    super.key,
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

class BaziChartHiddenStemCell extends StatelessWidget {
  const BaziChartHiddenStemCell({super.key, required this.pillar});

  final Pillar pillar;

  @override
  Widget build(BuildContext context) {
    if (pillar.hiddenStems.isEmpty) {
      return const BaziChartTableText('—', muted: true);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final h in pillar.hiddenStems)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: FiveElementChar(
              text: baziChartRuleEngine.stemElementLabel(h.stem),
              color: FiveElementColors.byStem(h.stem),
              large: false,
            ),
          ),
      ],
    );
  }
}

class BaziChartStackedLines extends StatelessWidget {
  const BaziChartStackedLines(this.lines, {super.key, this.muted = false});

  final List<String> lines;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const BaziChartTableText('—', muted: true);
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

String seatGrowthPhaseFor(Pillar pillar) {
  if (pillar.seatGrowthPhase.isNotEmpty) return pillar.seatGrowthPhase;
  return baziChartRuleEngine.growthPhaseFor(
    dayMasterStem: pillar.stem,
    branch: pillar.branch,
  );
}

class BaziChartShenshaCell extends StatelessWidget {
  const BaziChartShenshaCell({super.key, required this.items});

  final List<ShenshaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const BaziChartTableText('—', muted: true);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: GestureDetector(
              onTap: () => showBaziShenshaDetail(context, item),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                style: BaziChartTextStyles.shensha(
                  color: shenshaColor(item.name),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Color shenshaColor(String name) {
  const auspicious = {
    '天乙贵人', '太极贵人', '福星贵人', '天德贵人', '月德贵人',
    '天德合', '月德合', '天官贵人',
    '文昌', '学堂', '词馆', '禄神', '金舆', '国印贵人', '暗禄',
    '天厨贵人', '德秀贵人', '天赦日', '天医',
    '红鸾', '天喜', '将星', '三奇贵人', '十灵日', '六秀日',
    '日德', '日贵', '进神',
  };
  const inauspicious = {
    '亡神', '劫煞', '灾煞', '月煞', '羊刃', '飞刃',
    '孤辰', '寡宿', '魁罡', '十恶大败', '孤鸾煞', '阴错阳差',
    '丧门', '吊客', '披麻', '血刃',
    '红艳煞', '流霞', '四废日', '八专日', '九丑日',
    '天转', '地转', '天罗', '地网',
    '大耗', '小耗', '五鬼', '元辰', '勾煞', '绞煞', '退神', '挂剑煞',
  };
  if (auspicious.contains(name)) return AppColors.gold;
  if (inauspicious.contains(name)) return AppColors.cinnabar;
  return AppColors.deepGray;
}

String shenshaCategory(String name) {
  const auspicious = {
    '天乙贵人', '太极贵人', '福星贵人', '天德贵人', '月德贵人',
    '天德合', '月德合', '天官贵人',
    '文昌', '学堂', '词馆', '禄神', '金舆', '国印贵人', '暗禄',
    '天厨贵人', '德秀贵人', '天赦日', '天医',
    '红鸾', '天喜', '将星', '三奇贵人', '十灵日', '六秀日',
    '日德', '日贵', '进神',
  };
  const inauspicious = {
    '亡神', '劫煞', '灾煞', '月煞', '羊刃', '飞刃',
    '孤辰', '寡宿', '魁罡', '十恶大败', '孤鸾煞', '阴错阳差',
    '丧门', '吊客', '披麻', '血刃',
    '红艳煞', '流霞', '四废日', '八专日', '九丑日',
    '天转', '地转', '天罗', '地网',
    '大耗', '小耗', '五鬼', '元辰', '勾煞', '绞煞', '退神', '挂剑煞',
  };
  if (auspicious.contains(name)) return '吉';
  if (inauspicious.contains(name)) return '凶';
  return '平';
}

void showBaziShenshaDetail(BuildContext context, ShenshaItem item) {
  final category = shenshaCategory(item.name);
  final color = shenshaColor(item.name);
  showDialog<void>(
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
