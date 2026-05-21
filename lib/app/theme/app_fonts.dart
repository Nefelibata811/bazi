import 'package:flutter/foundation.dart';

/// 国内友好、零下载：Web/桌面优先系统自带中文字体，不依赖 Google CDN 或大型 ttf 包。
abstract final class AppFonts {
  /// Windows / 多数浏览器优先；Mac 会落到 [fallback] 里的 PingFang SC。
  static const String primary = 'Microsoft YaHei';

  static const List<String> fallback = [
    'PingFang SC',
    '微软雅黑',
    'SimHei',
    'Helvetica Neue',
    'sans-serif',
  ];

  /// 大运时间轴等需要略「传统」感的场景，仍用系统宋体类，不打包 Noto Serif。
  static const String serifPrimary = 'SimSun';
  static const List<String> serifFallback = [
    'Songti SC',
    'STSong',
    'NSimSun',
    'serif',
  ];

  static String? themeFontFamily() => primary;

  static List<String> themeFontFamilyFallback() => fallback;

  /// Web 不打包字体；原生若以后需要可在此扩展。
  static bool get bundlesFonts => !kIsWeb;
}
