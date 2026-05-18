import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared splash / loading screen for app bootstrap and login prefs load.
class AppSplash extends StatelessWidget {
  const AppSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('八  字', style: textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(
              'B A Z I',
              style: textTheme.bodySmall?.copyWith(
                letterSpacing: 6,
                color: AppColors.deepGray,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
