import 'package:flutter/material.dart';

class AppColors {
  static const paper = Color(0xFFF7F3EC);
  static const rice = Color(0xFFF1ECE3);
  static const ink = Color(0xFF1F1F1B);
  static const deepGray = Color(0xFF4A4A45);
  static const cinnabar = Color(0xFFB54D3E);
  static const gold = Color(0xFFC7A55B);
  static const line = Color(0xFFE6DED2);

  static const wood = Color(0xFF5E7D68);
  static const fire = Color(0xFFB86A5A);
  static const earth = Color(0xFFB3946D);
  static const metal = Color(0xFF9CA3AF);
  static const water = Color(0xFF4C6175);

  static Color fiveElementByStem(String stem) {
    const woodStems = {'甲', '乙'};
    const fireStems = {'丙', '丁'};
    const earthStems = {'戊', '己'};
    const metalStems = {'庚', '辛'};
    const waterStems = {'壬', '癸'};

    if (woodStems.contains(stem)) return wood;
    if (fireStems.contains(stem)) return fire;
    if (earthStems.contains(stem)) return earth;
    if (metalStems.contains(stem)) return metal;
    if (waterStems.contains(stem)) return water;
    return ink;
  }
}
