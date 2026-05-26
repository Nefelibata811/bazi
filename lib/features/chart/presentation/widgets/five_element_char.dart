import 'package:flutter/material.dart';

import '../../../../app/theme/app_fonts.dart';
import '../../../../app/theme/five_element_colors.dart';

/// 五行着色的干支 / 藏干文字（仅改字色，无底框）。
class FiveElementChar extends StatelessWidget {
  const FiveElementChar({
    super.key,
    required this.text,
    required this.color,
    this.large = true,
  });

  final String text;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty || text == '—') {
      return Text(
        text.isEmpty ? '—' : text,
        textAlign: TextAlign.center,
        style: BaziChartTextStyles.cellMuted(),
      );
    }

    if (!large) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: BaziChartTextStyles.stackedColored(color: color),
      );
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: BaziChartTextStyles.ganZhi(color: color).copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// 干支两字分色：天干按天干五行，地支按地支五行。
class FiveElementGanZhi extends StatelessWidget {
  const FiveElementGanZhi({
    super.key,
    required this.ganZhi,
    this.style,
    this.textAlign = TextAlign.center,
  });

  final String ganZhi;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    if (ganZhi.isEmpty) return const SizedBox.shrink();
    final base = style ?? BaziChartTextStyles.ganZhi(color: FiveElementColors.wood);
    if (ganZhi.length == 1) {
      return Text(
        ganZhi,
        textAlign: textAlign,
        style: base.copyWith(
          color: FiveElementColors.byStem(ganZhi),
          fontWeight: FontWeight.w700,
        ),
      );
    }
    final stem = ganZhi[0];
    final branch = ganZhi.length > 1 ? ganZhi[1] : '';
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: stem,
            style: base.copyWith(
              color: FiveElementColors.byStem(stem),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (branch.isNotEmpty)
            TextSpan(
              text: branch,
              style: base.copyWith(
                color: FiveElementColors.byBranch(branch),
                fontWeight: FontWeight.w700,
              ),
            ),
          if (ganZhi.length > 2)
            TextSpan(
              text: ganZhi.substring(2),
              style: base,
            ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

/// 五行图例条。
class FiveElementLegend extends StatelessWidget {
  const FiveElementLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final label in FiveElementColors.labels)
          _LegendChip(label: label),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = FiveElementColors.byLabel(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: BaziChartTextStyles.cell(
            bold: true,
            color: color,
          ),
        ),
      ],
    );
  }
}
