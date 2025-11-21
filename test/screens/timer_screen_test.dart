import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:burpeebata/screens/timer_screen.dart';
import 'package:burpeebata/models/workout_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock the Wakelock platform channel
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('github.com/peerrj/flutter_wakelock'),
      (MethodCall methodCall) async {
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('github.com/peerrj/flutter_wakelock'),
      null,
    );
  });

  Widget createTestWidget(WorkoutConfig config) {
    return MaterialApp(
      home: TimerScreen(config: config),
    );
  }

  group('TimerScreen', () {
    testWidgets('renders without error', (tester) async {
      const config = WorkoutConfig(
        repsPerSet: 5,
        secondsPerSet: 20,
        numberOfSets: 3,
      );

      await tester.pumpWidget(createTestWidget(config));
      await tester.pump();

      // Just verify the screen renders
      expect(find.byType(TimerScreen), findsOneWidget);
    });

    testWidgets('displays UI controls', (tester) async {
      const config = WorkoutConfig(
        repsPerSet: 5,
        secondsPerSet: 20,
        numberOfSets: 1,
      );

      await tester.pumpWidget(createTestWidget(config));
      await tester.pump();

      // Verify basic UI elements are present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNWidgets(2));
    });
  });
}
