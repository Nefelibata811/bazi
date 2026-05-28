// 文件：应用fonts
//
// 路径：`lib/app/theme/app_fonts.dart`。
//
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 国内友好、零下载：Web/桌面优先系统自带中文字体，不依赖 Google CDN 或大型 ttf 包。
abstract final class AppFonts {
  /// Windows / 多数浏览器优先；Mac 会落到 [fallback] 里的 PingFang SC。
  static const String primary = 'Microsoft YaHei';

  static const List<String> fallback = [
    'PingFang SC',
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    '微软雅黑',
    'SimHei',
    'Droid Sans Fallback',
    'Helvetica Neue',
    'sans-serif',
  ];

  /// 大运时间轴、四柱干支等需要略「传统」感的场景，仍用系统宋体类，不打包 Noto Serif。
  static const String serifPrimary = 'SimSun';
  static const List<String> serifFallback = [
    'Songti SC',
    'STSong',
    'Noto Serif CJK SC',
    'NSimSun',
    'serif',
  ];

  static String? themeFontFamily() => primary;

  static List<String> themeFontFamilyFallback() => fallback;

  /// Web 不打包字体；原生若以后需要可在此扩展。
  static bool get bundlesFonts => !kIsWeb;

  static TextTheme applyTo(TextTheme base) {
    return base.apply(
      fontFamily: themeFontFamily(),
      fontFamilyFallback: themeFontFamilyFallback(),
    );
  }
}

/// 四柱排盘表格专用字号与字重（与全局 [TextTheme] 区分）。
abstract final class BaziChartTextStyles {
  static TextStyle _sans({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double height = 1.35,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: AppFonts.primary,
      fontFamilyFallback: AppFonts.fallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _serif({
    required double size,
    FontWeight weight = FontWeight.w600,
    required Color color,
    double height = 1.05,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: AppFonts.serifPrimary,
      fontFamilyFallback: AppFonts.serifFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// 左侧行名：主星、天干、藏干…
  static TextStyle rowLabel({Color color = AppColors.deepGray}) => _sans(
        size: 13,
        weight: FontWeight.w500,
        color: color,
        height: 1.25,
        letterSpacing: 1.4,
      );

  /// 表头柱名
  static TextStyle headerPillar({Color color = AppColors.gold}) => _sans(
        size: 15,
        weight: FontWeight.w600,
        color: color,
        height: 1.2,
        letterSpacing: 0.6,
      );

  /// 表头柱下干支
  static TextStyle headerGanZhi({Color color = Colors.white}) => _serif(
        size: 14,
        weight: FontWeight.w500,
        color: color.withValues(alpha: 0.78),
        height: 1.15,
        letterSpacing: 1,
      );

  /// 天干 / 地支大字
  static TextStyle ganZhi({required Color color}) => _serif(
        size: 32,
        weight: FontWeight.w600,
        color: color,
        height: 1.0,
        letterSpacing: 4,
      );

  /// 主星、纳音等单元格正文
  static TextStyle cell({bool bold = false, Color color = AppColors.ink}) =>
      _sans(
        size: 13,
        weight: bold ? FontWeight.w600 : FontWeight.w500,
        color: color,
        height: 1.4,
      );

  static TextStyle cellMuted() => cell(color: AppColors.deepGray.withValues(alpha: 0.42));

  /// 藏干、副星竖排
  static TextStyle stacked({bool muted = false}) => _sans(
        size: 12,
        weight: FontWeight.w500,
        color: muted
            ? AppColors.deepGray.withValues(alpha: 0.72)
            : AppColors.ink,
        height: 1.5,
      );

  /// 藏干五行着色
  static TextStyle stackedColored({required Color color}) => _sans(
        size: 13,
        weight: FontWeight.w700,
        color: color,
        height: 1.5,
        letterSpacing: 0.3,
      );

  /// 神煞
  static TextStyle shensha({required Color color}) => _sans(
        size: 12,
        weight: FontWeight.w600,
        color: color,
        height: 1.45,
        letterSpacing: 0.2,
      );
}
