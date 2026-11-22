import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_app_factory/main.dart';

void main() {
  testWidgets('renders the actual app shell', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AndroidAppFactory());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Android App Factory'), findsWidgets);
  });
}
