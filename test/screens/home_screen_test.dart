import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:burpeebata/screens/home_screen.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }

  group('HomeScreen Number Inputs', () {
    group('Initial Display', () {
      testWidgets('displays all number input fields with default values', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify all labels are present
        expect(find.text('Reps per Set'), findsOneWidget);
        expect(find.text('Seconds per Set'), findsOneWidget);
        expect(find.text('Number of Sets'), findsOneWidget);
        expect(find.text('Rest Between Sets (sec)'), findsOneWidget);

        // Verify default values are displayed in text fields
        final textFields = find.byType(TextFormField);
        expect(textFields, findsNWidgets(4));

        // Check default values (10, 20, 8, 10)
        expect(find.text('10'), findsNWidgets(2)); // Reps and Rest
        expect(find.text('20'), findsOneWidget); // Seconds
        expect(find.text('8'), findsOneWidget); // Sets
      });

      testWidgets('displays plus and minus buttons for each input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // 4 inputs * 2 buttons each = 8 icon buttons
        expect(find.byIcon(Icons.add), findsNWidgets(4));
        expect(find.byIcon(Icons.remove), findsNWidgets(4));
      });
    });

    group('Increment Button', () {
      testWidgets('increments Reps per Set by 1', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the first add button (Reps per Set)
        final addButtons = find.byIcon(Icons.add);
        await tester.tap(addButtons.first);
        await tester.pump();

        // Value should increase from 10 to 11
        expect(find.text('11'), findsOneWidget);
      });

      testWidgets('does not exceed maximum value', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap the Reps per Set add button 20 times (10 + 20 = 30, which is max)
        final addButtons = find.byIcon(Icons.add);
        for (int i = 0; i < 25; i++) {
          await tester.tap(addButtons.first);
          await tester.pump();
        }

        // Value should be capped at 30 (max for Reps per Set)
        expect(find.text('30'), findsOneWidget);
      });

      testWidgets('disables button at maximum value', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap to reach maximum
        final addButtons = find.byIcon(Icons.add);
        for (int i = 0; i < 20; i++) {
          await tester.tap(addButtons.first);
          await tester.pump();
        }

        // The button should still be there but disabled
        final addButton = tester.widget<IconButton>(
          find.ancestor(
            of: addButtons.first,
            matching: find.byType(IconButton),
          ),
        );
        expect(addButton.onPressed, isNull);
      });
    });

    group('Decrement Button', () {
      testWidgets('decrements Reps per Set by 1', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the first remove button (Reps per Set)
        final removeButtons = find.byIcon(Icons.remove);
        await tester.tap(removeButtons.first);
        await tester.pump();

        // Value should decrease from 10 to 9
        expect(find.text('9'), findsOneWidget);
      });

      testWidgets('does not go below minimum value', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap the Reps per Set remove button many times
        final removeButtons = find.byIcon(Icons.remove);
        for (int i = 0; i < 15; i++) {
          await tester.tap(removeButtons.first);
          await tester.pump();
        }

        // Value should be at minimum 1 (min for Reps per Set)
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('disables button at minimum value', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap to reach minimum
        final removeButtons = find.byIcon(Icons.remove);
        for (int i = 0; i < 10; i++) {
          await tester.tap(removeButtons.first);
          await tester.pump();
        }

        // The button should be disabled
        final removeButton = tester.widget<IconButton>(
          find.ancestor(
            of: removeButtons.first,
            matching: find.byType(IconButton),
          ),
        );
        expect(removeButton.onPressed, isNull);
      });

      testWidgets('Rest Between Sets can go to 0', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the fourth remove button (Rest Between Sets)
        final removeButtons = find.byIcon(Icons.remove);
        final restRemoveButton = removeButtons.at(3);

        // Tap 10 times (default is 10, min is 0)
        for (int i = 0; i < 10; i++) {
          await tester.tap(restRemoveButton);
          await tester.pump();
        }

        // Value should be at 0
        expect(find.text('0'), findsOneWidget);
      });
    });

    group('Direct Input', () {
      testWidgets('accepts valid integer input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the first text field (Reps per Set)
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, '15');
        await tester.pump();

        // Value should be updated
        expect(find.text('15'), findsOneWidget);
      });

      testWidgets('clamps value to maximum when input exceeds max', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, '50');
        await tester.pump();

        // Value should be clamped to 30 (max for Reps per Set)
        expect(find.text('30'), findsOneWidget);
      });

      testWidgets('clamps value to minimum when input below min', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, '0');
        await tester.pump();

        // Value should be clamped to 1 (min for Reps per Set)
        expect(find.text('1'), findsOneWidget);
      });
    });

    group('Boundary Conditions', () {
      testWidgets('Seconds per Set respects 1-60 range', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find second set of buttons (Seconds per Set)
        final addButtons = find.byIcon(Icons.add);
        final secondsAddButton = addButtons.at(1);

        // Tap to reach maximum (from 20 to 60)
        for (int i = 0; i < 45; i++) {
          await tester.tap(secondsAddButton);
          await tester.pump();
        }

        // Should be capped at 60
        expect(find.text('60'), findsOneWidget);
      });

      testWidgets('Number of Sets respects 1-20 range', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find third set of buttons (Number of Sets)
        final addButtons = find.byIcon(Icons.add);
        final setsAddButton = addButtons.at(2);

        // Tap to reach maximum (from 8 to 20)
        for (int i = 0; i < 15; i++) {
          await tester.tap(setsAddButton);
          await tester.pump();
        }

        // Should be capped at 20 (note: '20' appears twice - once for Number of Sets
        // at max and once for Seconds per Set default value)
        expect(find.text('20'), findsNWidgets(2));
      });
    });

    group('Total Workout Time Updates', () {
      testWidgets('updates total time when values change', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Initial total: 8 sets * 20 sec + 7 rest * 10 sec = 230 sec = 3:50
        expect(find.text('3:50'), findsOneWidget);
        expect(find.text('8 sets \u00d7 10 reps = 80 total reps'), findsOneWidget);

        // Increase number of sets from 8 to 9
        final addButtons = find.byIcon(Icons.add);
        final setsAddButton = addButtons.at(2);
        await tester.tap(setsAddButton);
        await tester.pump();

        // New total: 9 sets * 20 sec + 8 rest * 10 sec = 260 sec = 4:20
        expect(find.text('4:20'), findsOneWidget);
        expect(find.text('9 sets \u00d7 10 reps = 90 total reps'), findsOneWidget);
      });

      testWidgets('updates total reps when reps per set changes', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Increase reps per set from 10 to 11
        final addButtons = find.byIcon(Icons.add);
        await tester.tap(addButtons.first);
        await tester.pump();

        expect(find.text('8 sets \u00d7 11 reps = 88 total reps'), findsOneWidget);
      });
    });
  });
}
