// 文件：应用colors
//
// 路径：`lib/app/theme/app_colors.dart`。
//
import 'package:flutter/material.dart';

import 'five_element_colors.dart';

/// 类 `AppColors`：实现 App Colors 相关逻辑。
class AppColors {
  static const paper = Color(0xFFF7F3EC);
  static const rice = Color(0xFFF1ECE3);
  static const ink = Color(0xFF1F1F1B);
  static const deepGray = Color(0xFF4A4A45);
  static const cinnabar = Color(0xFFB54D3E);
  static const gold = Color(0xFFC7A55B);
  static const line = Color(0xFFE6DED2);

  static Color get wood => FiveElementColors.wood;
  static Color get fire => FiveElementColors.fire;
  static Color get earth => FiveElementColors.earth;
  static Color get metal => FiveElementColors.metal;
  static Color get water => FiveElementColors.water;

  static Color fiveElementByStem(String stem) =>
      FiveElementColors.byStem(stem);

  static Color fiveElementByBranch(String branch) =>
      FiveElementColors.byBranch(branch);

  static Color fiveElementByLabel(String label) =>
      FiveElementColors.byLabel(label);
}
