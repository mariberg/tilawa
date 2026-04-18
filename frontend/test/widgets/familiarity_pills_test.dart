import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_prep/theme/app_colors.dart';
import 'package:quran_prep/widgets/familiarity_pills.dart';

void main() {
  group('FamiliarityPillsState.reset()', () {
    testWidgets('clears the selection after a pill is tapped',
        (WidgetTester tester) async {
      final key = GlobalKey<FamiliarityPillsState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamiliarityPills(key: key),
          ),
        ),
      );

      // Tap "Well known" pill to select it.
      await tester.tap(find.text('Well known'));
      await tester.pump();

      // Verify the pill is visually selected (AppColors.primaryLight background).
      Container selectedContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Well known'),
          matching: find.byType(Container),
        ),
      );
      BoxDecoration selectedDecoration =
          selectedContainer.decoration! as BoxDecoration;
      expect(selectedDecoration.color, equals(AppColors.primaryLight));

      // Call reset().
      key.currentState!.reset();
      await tester.pump();

      // Verify all pills have transparent background (no selection).
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(FamiliarityPills),
          matching: find.byType(Container),
        ),
      );

      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration! as BoxDecoration;
          expect(decoration.color, equals(Colors.transparent),
              reason: 'All pills should be unselected after reset()');
        }
      }
    });
  });

  group('FamiliarityPills visual reset (didPopNext scenario)', () {
    testWidgets('pills are visually cleared after reset() is triggered',
        (WidgetTester tester) async {
      final key = GlobalKey<FamiliarityPillsState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamiliarityPills(key: key),
          ),
        ),
      );

      // Tap "Somewhat familiar" to select it.
      await tester.tap(find.text('Somewhat familiar'));
      await tester.pump();

      // Verify the pill is visually selected.
      final selectedContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Somewhat familiar'),
          matching: find.byType(Container),
        ),
      );
      final selectedDec = selectedContainer.decoration! as BoxDecoration;
      expect(selectedDec.color, equals(AppColors.primaryLight));

      // Simulate what didPopNext() does: call reset().
      key.currentState!.reset();
      await tester.pump();

      // Verify no pill has the selected background color.
      for (final label in ['New', 'Somewhat familiar', 'Well known']) {
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(Container),
          ),
        );
        final dec = container.decoration! as BoxDecoration;
        expect(dec.color, equals(Colors.transparent),
            reason: '"$label" pill should be unselected after reset()');
      }
    });
  });

  group('FamiliarityPills onChanged after reset (familiarity value reset)', () {
    testWidgets('familiarity value resets correctly through a reset cycle',
        (WidgetTester tester) async {
      final key = GlobalKey<FamiliarityPillsState>();
      String? lastFamiliarity;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamiliarityPills(
              key: key,
              onChanged: (value) => lastFamiliarity = value,
            ),
          ),
        ),
      );

      // Tap "Well known" — verify callback received "Well known".
      await tester.tap(find.text('Well known'));
      await tester.pump();
      expect(lastFamiliarity, equals('Well known'));

      // Call reset() — simulates what didPopNext() triggers.
      key.currentState!.reset();
      await tester.pump();

      // Verify pills are visually cleared.
      for (final label in ['New', 'Somewhat familiar', 'Well known']) {
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(Container),
          ),
        );
        final dec = container.decoration! as BoxDecoration;
        expect(dec.color, equals(Colors.transparent),
            reason: '"$label" should be unselected after reset()');
      }

      // Tap "New" — verify callback receives "New" (re-selection after reset).
      await tester.tap(find.text('New'));
      await tester.pump();
      expect(lastFamiliarity, equals('New'));

      // Verify "New" pill is now visually selected.
      final newContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('New'),
          matching: find.byType(Container),
        ),
      );
      final newDec = newContainer.decoration! as BoxDecoration;
      expect(newDec.color, equals(AppColors.primaryLight));
    });
  });
}
