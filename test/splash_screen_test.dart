import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lunti_app/screens/splash_screen.dart';

void main() {
  testWidgets('splash shows the LUNTI mark and loading copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LuntiSplashScreen()));

    expect(find.text('LUNTI'), findsOneWidget);
    expect(find.textContaining('Rooted in craft'), findsOneWidget);
    expect(find.byIcon(Icons.eco_rounded), findsOneWidget);

    // The pulse repeats forever, so pump fixed frames instead of settling.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    expect(tester.takeException(), isNull);
  });

  testWidgets('splash holds still when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: LuntiSplashScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('LUNTI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
