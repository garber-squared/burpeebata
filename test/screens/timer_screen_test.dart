import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:burpeebata/screens/timer_screen.dart';
import 'package:burpeebata/services/timer_service.dart';
import 'package:burpeebata/models/workout_config.dart';

@GenerateMocks([TimerService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget(WorkoutConfig config) {
    return MaterialApp(
      home: TimerScreen(config: config),
    );
  }

  group('TimerScreen Rep Display', () {
    group('Rep counter visibility', () {
      testWidgets('displays static reps text during countdown phase', (tester) async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 3,
        );

        await tester.pumpWidget(createTestWidget(config));
        await tester.pump();

        // During countdown, should show static "X reps" text
        expect(find.text('5 reps'), findsOneWidget);
        // Should not show dynamic rep counter format
        expect(find.textContaining('Rep '), findsNothing);
      });

      testWidgets('displays rep counter during work phase', (tester) async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 1,
        );

        await tester.pumpWidget(createTestWidget(config));

        // Wait for countdown (3s) to finish and work to start
        await tester.pump(const Duration(seconds: 4));

        // Should show rep counter during work phase
        expect(find.textContaining('Rep '), findsOneWidget);
        expect(find.textContaining('/5'), findsOneWidget);
      });

      testWidgets('displays static reps text during rest phase', (tester) async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 5,
          numberOfSets: 2,
          restBetweenSets: 10,
        );

        await tester.pumpWidget(createTestWidget(config));

        // Wait for countdown (3s) + work (5s) to finish
        await tester.pump(const Duration(seconds: 9));

        // During rest, should show static "X reps" text
        expect(find.text('5 reps'), findsOneWidget);
      });
    });

    group('Rep counter format', () {
      testWidgets('shows correct format Rep X/Y', (tester) async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 1,
        );

        await tester.pumpWidget(createTestWidget(config));

        // Wait for countdown to finish
        await tester.pump(const Duration(seconds: 4));

        // Should show "Rep 1/5" at start
        expect(find.text('Rep 1/5'), findsOneWidget);
      });

      testWidgets('rep counter updates as time progresses', (tester) async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 1,
        );

        await tester.pumpWidget(createTestWidget(config));

        // Wait for countdown (3s) + 4s work (one rep interval at 4s/rep)
        await tester.pump(const Duration(seconds: 8));

        // Should be on rep 2 after 4 seconds of work
        expect(find.text('Rep 2/5'), findsOneWidget);
      });

      testWidgets('handles different rep counts', (tester) async {
        const config = WorkoutConfig(
          repsPerSet: 10,
          secondsPerSet: 30,
          numberOfSets: 1,
        );

        await tester.pumpWidget(createTestWidget(config));

        // Wait for countdown to finish
        await tester.pump(const Duration(seconds: 4));

        // Should show /10 for total reps
        expect(find.textContaining('/10'), findsOneWidget);
      });
    });

    group('Rep counter with single rep', () {
      testWidgets('shows Rep 1/1 when repsPerSet is 1', (tester) async {
        const config = WorkoutConfig(
          repsPerSet: 1,
          secondsPerSet: 10,
          numberOfSets: 1,
        );

        await tester.pumpWidget(createTestWidget(config));

        // Wait for countdown to finish
        await tester.pump(const Duration(seconds: 4));

        // Should show "Rep 1/1" throughout the work period
        expect(find.text('Rep 1/1'), findsOneWidget);
      });
    });

    group('Set information display', () {
      testWidgets('displays set information alongside rep counter', (tester) async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 3,
        );

        await tester.pumpWidget(createTestWidget(config));

        // Wait for countdown to finish
        await tester.pump(const Duration(seconds: 4));

        // Should show both set info and rep counter
        expect(find.text('Set 1 of 3'), findsOneWidget);
        expect(find.textContaining('Rep '), findsOneWidget);
      });
    });
  });
}
