import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/flowing_year.dart';
import '../../../../domain/entities/luck_cycle.dart';
import '../../../chart/presentation/widgets/five_element_char.dart';

class LuckCycleTimeline extends StatefulWidget {
  const LuckCycleTimeline({
    super.key,
    required this.luckCycles,
    required this.startAgeText,
  });

  final List<LuckCycle> luckCycles;
  final String startAgeText;

  @override
  State<LuckCycleTimeline> createState() => _LuckCycleTimelineState();
}

class _LuckCycleTimelineState extends State<LuckCycleTimeline> {
  int? _expandedIndex;
  int? _expandedYearIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('大运排盘', style: textTheme.titleLarge),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '起运 ${widget.startAgeText}',
                    style: textTheme.labelMedium?.copyWith(color: AppColors.gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.luckCycles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cycle = widget.luckCycles[index];
                final isExpanded = _expandedIndex == index;
                final branchChar = cycle.ganZhi.length > 1
                    ? cycle.ganZhi[1]
                    : '';
                final branchColor = AppColors.fiveElementByBranch(branchChar);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpanded
                          ? branchColor.withValues(alpha: 0.3)
                          : AppColors.line,
                    ),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedIndex = null;
                              _expandedYearIndex = null;
                            } else {
                              _expandedIndex = index;
                              _expandedYearIndex = null;
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: branchColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  cycle.isPreStart ? '小' : '${cycle.index}',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: branchColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FiveElementGanZhi(
                                      ganZhi: cycle.ganZhi,
                                      style: textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cycle.tenGod,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.deepGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${cycle.startAge}-${cycle.endAge}岁',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${cycle.startYear}-${cycle.endYear}年',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                                color: AppColors.deepGray,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: branchColor.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cycle.isPreStart ? '流年 · 小运' : '流年',
                                style: textTheme.labelMedium?.copyWith(
                                  color: AppColors.deepGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (var yi = 0; yi < cycle.flowingYears.length; yi++)
                                    _FlowingYearChip(
                                      fy: cycle.flowingYears[yi],
                                      isSelected:
                                          _expandedIndex == index &&
                                          _expandedYearIndex == yi,
                                      onTap: () {
                                        setState(() {
                                          if (_expandedYearIndex == yi) {
                                            _expandedYearIndex = null;
                                          } else {
                                            _expandedYearIndex = yi;
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                              if (_expandedIndex == index &&
                                  _expandedYearIndex != null &&
                                  _expandedYearIndex! <
                                      cycle.flowingYears.length) ...[
                                const SizedBox(height: 12),
                                Text(
                                  '流月 · ${cycle.flowingYears[_expandedYearIndex!].year}年',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: AppColors.deepGray,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: cycle
                                      .flowingYears[_expandedYearIndex!]
                                      .flowingMonths
                                      .map(
                                        (fm) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.84),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.line,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                fm.monthName,
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              FiveElementGanZhi(
                                                ganZhi: fm.ganZhi,
                                                style: textTheme.labelSmall,
                                              ),
                                              Text(
                                                fm.tenGod,
                                                style: textTheme.labelSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowingYearChip extends StatelessWidget {
  const _FlowingYearChip({
    required this.fy,
    required this.isSelected,
    required this.onTap,
  });

  final FlowingYear fy;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = isSelected
        ? AppColors.gold.withValues(alpha: 0.5)
        : AppColors.line;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.gold.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Text(
                '${fy.year}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              FiveElementGanZhi(
                ganZhi: fy.ganZhi,
                style: textTheme.labelSmall,
              ),
              Text(fy.tenGod, style: textTheme.labelSmall),
              if (fy.xiaoYunGanZhi != null && fy.xiaoYunGanZhi!.isNotEmpty) ...[
                Text(
                  '小运',
                  style: textTheme.labelSmall?.copyWith(color: AppColors.gold),
                ),
                FiveElementGanZhi(
                  ganZhi: fy.xiaoYunGanZhi!,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.gold),
                ),
              ],
              if (fy.flowingMonths.isNotEmpty)
                Text(
                  '流月',
                  style: textTheme.labelSmall?.copyWith(
                    color: isSelected ? AppColors.gold : AppColors.deepGray,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
