// 文件：五五行colors
//
// 路径：`lib/app/theme/five_element_colors.dart`。
//
import 'package:flutter/material.dart';

/// 排盘用五行高对比色：木绿、火红、土褐、金亮黄、水蓝。
abstract final class FiveElementColors {
  static const wood = Color(0xFF16A34A);
  static const fire = Color(0xFFDC2626);
  /// 土：偏褐、沉，与金区分。
  static const earth = Color(0xFF9A5B2E);
  /// 金：明黄 / 金色，比土更亮更艳。
  static const metal = Color(0xFFFFB300);
  static const water = Color(0xFF2563EB);

  static Color byStem(String stem) {
    switch (stem) {
      case '甲':
      case '乙':
        return wood;
      case '丙':
      case '丁':
        return fire;
      case '戊':
      case '己':
        return earth;
      case '庚':
      case '辛':
        return metal;
      case '壬':
      case '癸':
        return water;
      default:
        return const Color(0xFF1F1F1B);
    }
  }

  static Color byBranch(String branch) {
    switch (branch) {
      case '寅':
      case '卯':
        return wood;
      case '巳':
      case '午':
        return fire;
      case '辰':
      case '戌':
      case '丑':
      case '未':
        return earth;
      case '申':
      case '酉':
        return metal;
      case '亥':
      case '子':
        return water;
      default:
        return const Color(0xFF1F1F1B);
    }
  }

  static Color byLabel(String label) {
    switch (label) {
      case '木':
        return wood;
      case '火':
        return fire;
      case '土':
        return earth;
      case '金':
        return metal;
      case '水':
        return water;
      default:
        return const Color(0xFF1F1F1B);
    }
  }

  /// 「丁火」等：取首字天干定色。
  static Color byStemElementLabel(String label) {
    if (label.isEmpty) return const Color(0xFF1F1F1B);
    return byStem(label[0]);
  }

  static const labels = ['木', '火', '土', '金', '水'];
}
