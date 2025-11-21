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
        expect(find.text('Initial Countdown (sec)'), findsOneWidget);

        // Verify default values are displayed in text fields
        final textFields = find.byType(TextFormField);
        expect(textFields, findsNWidgets(5));

        // Check default values (5, 20, 10, 4, 10)
        expect(find.text('5'), findsOneWidget); // Reps
        expect(find.text('20'), findsOneWidget); // Seconds
        expect(find.text('10'), findsNWidgets(2)); // Sets and Initial Countdown both default to 10
        expect(find.text('4'), findsOneWidget); // Rest
      });

      testWidgets('displays plus and minus buttons for each input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // 5 inputs * 2 buttons each = 10 icon buttons
        expect(find.byIcon(Icons.add), findsNWidgets(5));
        expect(find.byIcon(Icons.remove), findsNWidgets(5));
      });
    });

    group('Increment Button', () {
      testWidgets('increments Reps per Set by 1', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the first add button (Reps per Set)
        final addButtons = find.byIcon(Icons.add);
        await tester.tap(addButtons.first);
        await tester.pump();

        // Value should increase from 5 to 6
        expect(find.text('6'), findsOneWidget);
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

        // Tap to reach maximum (from 5 to 30)
        final addButtons = find.byIcon(Icons.add);
        for (int i = 0; i < 25; i++) {
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

        // Value should decrease from 5 to 4
        // Note: '4' appears twice (Reps and Rest both at 4)
        expect(find.text('4'), findsNWidgets(2));
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

        // Tap to reach minimum (from 5 to 1)
        final removeButtons = find.byIcon(Icons.remove);
        for (int i = 0; i < 5; i++) {
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

        // Tap 4 times (default is 4, min is 0)
        for (int i = 0; i < 4; i++) {
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

        // Tap to reach maximum (from 10 to 20)
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

        // Initial total: 10 sets * 20 sec + 9 rest * 4 sec = 236 sec = 3:56
        expect(find.text('3:56'), findsOneWidget);
        expect(find.text('10 sets \u00d7 5 reps = 50 total reps'), findsOneWidget);

        // Increase number of sets from 10 to 11
        final addButtons = find.byIcon(Icons.add);
        final setsAddButton = addButtons.at(2);
        await tester.tap(setsAddButton);
        await tester.pump();

        // New total: 11 sets * 20 sec + 10 rest * 4 sec = 260 sec = 4:20
        expect(find.text('4:20'), findsOneWidget);
        expect(find.text('11 sets \u00d7 5 reps = 55 total reps'), findsOneWidget);
      });

      testWidgets('updates total reps when reps per set changes', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Increase reps per set from 5 to 6
        final addButtons = find.byIcon(Icons.add);
        await tester.tap(addButtons.first);
        await tester.pump();

        expect(find.text('10 sets \u00d7 6 reps = 60 total reps'), findsOneWidget);
      });
    });
  });
}
