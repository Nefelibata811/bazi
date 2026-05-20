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
