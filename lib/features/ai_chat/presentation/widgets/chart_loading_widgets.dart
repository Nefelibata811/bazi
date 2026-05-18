import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Stable, non-flickering loading for chart restore / switch.
class ChartSessionLoading extends StatelessWidget {
  const ChartSessionLoading({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: textTheme.titleSmall?.copyWith(color: AppColors.deepGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Top-of-sheet subtle refresh indicator (no full-page spinner flash).
class ChartListRefreshBar extends StatelessWidget {
  const ChartListRefreshBar({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.gold.withOpacity(0.06),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
