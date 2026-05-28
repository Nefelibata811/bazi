// 文件：单元测试 — 应用启动页
//
// 验证 应用启动页 的正确性与边界情况。
// 修改实现时请同步维护本测试。
//
import 'package:bazi_app/app/widgets/app_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppSplash 显示加载指示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppSplash()),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
