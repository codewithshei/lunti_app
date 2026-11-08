import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunti_app/app/app_theme.dart';
import 'package:lunti_app/widgets/lunti_card.dart';
import 'package:lunti_app/widgets/lunti_states.dart';

void main() {
  group('LuntiCard', () {
    testWidgets('renders a bordered, rounded surface', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LuntiCard(child: Text('Piece')),
            ),
          ),
        ),
      );

      final decoration = tester
          .widget<Container>(find.byType(Container).first)
          .decoration! as BoxDecoration;

      expect(decoration.color, LuntiPalette.light.surface);
      expect(decoration.borderRadius, BorderRadius.circular(LuntiRadii.md));
      expect(decoration.border, isA<Border>());
      expect(decoration.boxShadow, LuntiShadows.card);
    });

    testWidgets('flat variant has no shadow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LuntiCard.flat(child: Text('Piece')),
            ),
          ),
        ),
      );

      final decoration = tester
          .widget<Container>(find.byType(Container).first)
          .decoration! as BoxDecoration;
      expect(decoration.boxShadow, isEmpty);
    });

    testWidgets('tapping the card fires onTap once', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LuntiCard(
                onTap: () => taps++,
                child: const Text('Piece'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Piece'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });

  group('LuntiEmptyState', () {
    testWidgets('shows icon, title, message and action', (tester) async {
      var acted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LuntiEmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your bag is empty',
              message: 'Pieces you add will appear here.',
              actionLabel: 'Continue shopping',
              onAction: () => acted = true,
            ),
          ),
        ),
      );

      expect(find.text('Your bag is empty'), findsOneWidget);
      expect(find.text('Pieces you add will appear here.'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);

      await tester.tap(find.text('Continue shopping'));
      await tester.pumpAndSettle();
      expect(acted, isTrue);
    });

    testWidgets('omits the action when none is supplied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LuntiEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matches yet',
              message: 'Try another word.',
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('lays out from the top inside an unbounded scroll view',
        (tester) async {
      // A ListView gives its children unbounded height; the state must not
      // try to vertically center there (that would throw a layout error).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                LuntiEmptyState(
                  compact: true,
                  icon: Icons.search_off_rounded,
                  title: 'No matches yet',
                  message: 'Try another word.',
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('No matches yet'), findsOneWidget);
    });
  });

  group('LuntiErrorState', () {
    testWidgets('renders a retry action that fires', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LuntiErrorState(
              message: 'Could not load your orders.',
              onRetry: () => retries++,
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Could not load your orders.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(retries, 1);
    });
  });

  group('theme tokens', () {
    test('body copy is darker than the decorative secondary tone', () {
      // WCAG AA at 11-12px needs a darker tone than the brand grey when the
      // text sits on the sage tint.
      expect(
        LuntiPalette.light.textMuted.computeLuminance(),
        lessThan(LuntiPalette.light.textFaint.computeLuminance()),
      );
    });

    test('spacing scale is monotonic', () {
      expect(LuntiSpacing.xs, lessThan(LuntiSpacing.sm));
      expect(LuntiSpacing.sm, lessThan(LuntiSpacing.md));
      expect(LuntiSpacing.md, lessThan(LuntiSpacing.lg));
    });

    test('breakpoints are ordered', () {
      expect(
        LuntiBreakpoints.compact,
        lessThan(LuntiBreakpoints.medium),
      );
      expect(
        LuntiBreakpoints.medium,
        lessThan(LuntiBreakpoints.expanded),
      );
    });
  });
}
