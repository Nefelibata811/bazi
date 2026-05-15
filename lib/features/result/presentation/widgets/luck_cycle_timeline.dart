import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../domain/entities/luck_cycle.dart';

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
                    color: AppColors.gold.withOpacity(0.12),
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
                final branchColor = AppColors.fiveElementByStem(cycle.ganZhi[1]);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpanded
                          ? branchColor.withOpacity(0.3)
                          : AppColors.line,
                    ),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _expandedIndex =
                                isExpanded ? null : index;
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
                                  color: branchColor.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${cycle.index}',
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
                                    Text(
                                      cycle.ganZhi,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontFamily: 'NotoSerifSC',
                                      ),
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
                            color: branchColor.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '流年',
                                style: textTheme.labelMedium?.copyWith(
                                  color: AppColors.deepGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: cycle.flowingYears.map((fy) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.84),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.line,
                                      ),
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
                                        Text(
                                          fy.ganZhi,
                                          style: textTheme.labelSmall?.copyWith(
                                            fontFamily: 'NotoSerifSC',
                                            color: AppColors.fiveElementByStem(
                                              fy.ganZhi[0],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          fy.tenGod,
                                          style: textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
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
