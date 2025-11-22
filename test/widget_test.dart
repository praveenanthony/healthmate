import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:healthmate/main.dart';
import 'package:healthmate/features/screens/splash_screen.dart';

void main() {
  testWidgets('HealthMate app loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const ProviderScope(child: MyApp()),
      ),
    );

    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
