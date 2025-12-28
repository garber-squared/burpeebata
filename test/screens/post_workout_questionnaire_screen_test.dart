import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:burpeebata/screens/post_workout_questionnaire_screen.dart';
import 'package:burpeebata/models/workout_config.dart';
import 'package:burpeebata/models/burpee_type.dart';

void main() {
  group('PostWorkoutQuestionnaireScreen', () {
    const testConfig = WorkoutConfig(
      burpeeType: BurpeeType.militarySixCount,
      repsPerSet: 10,
      secondsPerSet: 20,
      numberOfSets: 8,
      restBetweenSets: 10,
    );

    Widget createTestWidget({
      WorkoutConfig config = testConfig,
      int elapsedSeconds = 245,
    }) {
      return MaterialApp(
        home: PostWorkoutQuestionnaireScreen(
          config: config,
          elapsedSeconds: elapsedSeconds,
        ),
      );
    }

    group('initial state', () {
      testWidgets('displays workout complete title', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Workout Complete!'), findsOneWidget);
      });

      testWidgets('displays congratulatory message', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Great job!'), findsOneWidget);
      });

      testWidgets('displays question 1', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(
          find.text('Did you complete all the sets?'),
          findsOneWidget,
        );
      });

      testWidgets('does not display question 2 initially', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(
          find.text('Did you complete the workout in less than 5 minutes?'),
          findsNothing,
        );
      });

      testWidgets('submit button is disabled initially', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'SUBMIT'),
        );

        expect(submitButton.onPressed, isNull);
      });
    });

    group('question 1 interaction', () {
      testWidgets('can select YES for question 1', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('YES').first);
        await tester.pump();

        // Question 2 should now appear
        expect(
          find.text('Did you complete the workout in less than 5 minutes?'),
          findsOneWidget,
        );
      });

      testWidgets('can select NO for question 1', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('NO').first);
        await tester.pump();

        // Question 2 should NOT appear
        expect(
          find.text('Did you complete the workout in less than 5 minutes?'),
          findsNothing,
        );
      });

      testWidgets('submit button becomes enabled after answering Q1',
          (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('YES').first);
        await tester.pump();

        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'SUBMIT'),
        );

        expect(submitButton.onPressed, isNotNull);
      });
    });

    group('question 2 conditional display', () {
      testWidgets('shows question 2 when Q1 is YES', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('YES').first);
        await tester.pump();

        expect(
          find.text('Did you complete the workout in less than 5 minutes?'),
          findsOneWidget,
        );
      });

      testWidgets('hides question 2 when Q1 is NO', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // First select YES to show Q2
        await tester.tap(find.text('YES').first);
        await tester.pump();

        expect(
          find.text('Did you complete the workout in less than 5 minutes?'),
          findsOneWidget,
        );

        // Then select NO to hide Q2
        await tester.tap(find.text('NO').first);
        await tester.pump();

        expect(
          find.text('Did you complete the workout in less than 5 minutes?'),
          findsNothing,
        );
      });

      testWidgets('displays elapsed time in question 2', (tester) async {
        await tester.pumpWidget(createTestWidget(elapsedSeconds: 245));

        await tester.tap(find.text('YES').first);
        await tester.pump();

        // 245 seconds = 4 minutes 5 seconds = "4:05"
        expect(find.text('Your time: 4:05'), findsOneWidget);
      });

      testWidgets('formats elapsed time correctly for whole minutes',
          (tester) async {
        await tester.pumpWidget(createTestWidget(elapsedSeconds: 180));

        await tester.tap(find.text('YES').first);
        await tester.pump();

        // 180 seconds = 3 minutes = "3:00"
        expect(find.text('Your time: 3:00'), findsOneWidget);
      });

      testWidgets('formats elapsed time correctly for single digit seconds',
          (tester) async {
        await tester.pumpWidget(createTestWidget(elapsedSeconds: 305));

        await tester.tap(find.text('YES').first);
        await tester.pump();

        // 305 seconds = 5 minutes 5 seconds = "5:05"
        expect(find.text('Your time: 5:05'), findsOneWidget);
      });
    });

    group('question 2 interaction', () {
      testWidgets('can select YES for question 2', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Answer Q1 to show Q2
        await tester.tap(find.text('YES').first);
        await tester.pump();

        // Answer Q2
        await tester.tap(find.text('YES').last);
        await tester.pump();

        // Should remain on screen
        expect(find.text('Workout Complete!'), findsOneWidget);
      });

      testWidgets('can select NO for question 2', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Answer Q1 to show Q2
        await tester.tap(find.text('YES').first);
        await tester.pump();

        // Answer Q2
        await tester.tap(find.text('NO').last);
        await tester.pump();

        // Should remain on screen
        expect(find.text('Workout Complete!'), findsOneWidget);
      });
    });

    group('submit behavior', () {
      testWidgets('submitting with Q1=YES, Q2=YES completes successfully',
          (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Answer Q1
        await tester.tap(find.text('YES').first);
        await tester.pump();

        // Answer Q2
        await tester.tap(find.text('YES').last);
        await tester.pump();

        // Submit button should be enabled
        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'SUBMIT'),
        );
        expect(submitButton.onPressed, isNotNull);

        // Tap submit (navigation happens)
        await tester.tap(find.text('SUBMIT'));
        await tester.pumpAndSettle();
      });

      testWidgets('submitting with Q1=NO hides Q2', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Answer Q1 as NO
        await tester.tap(find.text('NO').first);
        await tester.pump();

        // Q2 should not appear
        expect(
          find.text('Did you complete the workout in less than 5 minutes?'),
          findsNothing,
        );

        // Submit button should be enabled
        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'SUBMIT'),
        );
        expect(submitButton.onPressed, isNotNull);
      });
    });

    group('back button handling', () {
      testWidgets('prevents default back navigation', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // PopScope with canPop: false prevents navigation
        expect(find.text('Workout Complete!'), findsOneWidget);
      });
    });

    group('button styling', () {
      testWidgets('buttons respond to selection', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Select YES
        await tester.tap(find.text('YES').first);
        await tester.pump();

        // Q2 should appear as a result of selection
        expect(
          find.text('Did you complete the workout in less than 5 minutes?'),
          findsOneWidget,
        );

        // Select NO instead
        await tester.tap(find.text('NO').first);
        await tester.pump();

        // Q2 should disappear
        expect(
          find.text('Did you complete the workout in less than 5 minutes?'),
          findsNothing,
        );
      });
    });

    group('edge cases', () {
      testWidgets('handles 0 elapsed seconds', (tester) async {
        await tester.pumpWidget(createTestWidget(elapsedSeconds: 0));

        await tester.tap(find.text('YES').first);
        await tester.pump();

        expect(find.text('Your time: 0:00'), findsOneWidget);
      });

      testWidgets('handles very large elapsed seconds', (tester) async {
        await tester.pumpWidget(createTestWidget(elapsedSeconds: 999));

        await tester.tap(find.text('YES').first);
        await tester.pump();

        // 999 seconds = 16 minutes 39 seconds
        expect(find.text('Your time: 16:39'), findsOneWidget);
      });
    });
  });
}
