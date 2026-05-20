import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.cinnabar,
      brightness: Brightness.light,
      primary: AppColors.ink,
      secondary: AppColors.cinnabar,
      surface: Colors.white.withValues(alpha: 0.92),
      error: const Color(0xFFB3261E),
    );

    // Web 使用打包的 NotoSansSC，避免从 gstatic 拉字体失败导致「有按钮无文字」。
    final appFontFamily = kIsWeb ? 'NotoSansSC' : 'sans-serif';
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: appFontFamily,
      fontFamilyFallback: const [
        'PingFang SC',
        'Microsoft YaHei',
        'SimHei',
        'sans-serif',
      ],
    );

    var textTheme = base.textTheme.copyWith(
      displaySmall: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.2,
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.3,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.7,
        color: AppColors.ink,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        height: 1.65,
        color: AppColors.deepGray,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        height: 1.5,
        color: AppColors.deepGray,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.deepGray,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.deepGray,
      ),
    );
    textTheme = textTheme.apply(fontFamily: appFontFamily);
    final primaryTextTheme =
        base.primaryTextTheme.apply(fontFamily: appFontFamily);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      splashFactory: NoSplash.splashFactory,
      dividerColor: Colors.transparent,
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.line),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(
          color: const Color(0xFF8C867D),
          fontSize: 14,
          fontFamily: appFontFamily,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.cinnabar, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: appFontFamily,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.ink;
            }
            return Colors.white.withValues(alpha: 0.7);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.deepGray;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.line),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withValues(alpha: 0.86),
        selectedColor: AppColors.cinnabar.withValues(alpha: 0.12),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.deepGray,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.cinnabar;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.cinnabar.withValues(alpha: 0.25);
          }
          return AppColors.line;
        }),
      ),
    );
  }
}
