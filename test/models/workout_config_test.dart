import 'package:flutter_test/flutter_test.dart';
import 'package:burpeebata/models/workout_config.dart';
import 'package:burpeebata/models/burpee_type.dart';

void main() {
  group('WorkoutConfig', () {
    group('default values', () {
      test('has correct default values', () {
        const config = WorkoutConfig();

        expect(config.burpeeType, equals(BurpeeType.militarySixCount));
        expect(config.repsPerSet, equals(5));
        expect(config.secondsPerSet, equals(20));
        expect(config.numberOfSets, equals(10));
        expect(config.restBetweenSets, equals(4));
        expect(config.initialCountdown, equals(10));
      });
    });

    group('copyWith', () {
      test('creates copy with updated values', () {
        const config = WorkoutConfig();
        final copy = config.copyWith(
          burpeeType: BurpeeType.navySeal,
          repsPerSet: 15,
        );

        expect(copy.burpeeType, equals(BurpeeType.navySeal));
        expect(copy.repsPerSet, equals(15));
        expect(copy.secondsPerSet, equals(config.secondsPerSet));
        expect(copy.numberOfSets, equals(config.numberOfSets));
        expect(copy.restBetweenSets, equals(config.restBetweenSets));
        expect(copy.initialCountdown, equals(config.initialCountdown));
      });

      test('creates exact copy when no parameters provided', () {
        const config = WorkoutConfig(
          burpeeType: BurpeeType.navySeal,
          repsPerSet: 12,
          secondsPerSet: 30,
          numberOfSets: 5,
          restBetweenSets: 15,
          initialCountdown: 15,
        );
        final copy = config.copyWith();

        expect(copy.burpeeType, equals(config.burpeeType));
        expect(copy.repsPerSet, equals(config.repsPerSet));
        expect(copy.secondsPerSet, equals(config.secondsPerSet));
        expect(copy.numberOfSets, equals(config.numberOfSets));
        expect(copy.restBetweenSets, equals(config.restBetweenSets));
        expect(copy.initialCountdown, equals(config.initialCountdown));
      });

      test('copies initialCountdown correctly', () {
        const config = WorkoutConfig();
        final copy = config.copyWith(initialCountdown: 20);

        expect(copy.initialCountdown, equals(20));
        expect(copy.repsPerSet, equals(config.repsPerSet));
      });
    });

    group('totalWorkoutSeconds', () {
      test('calculates total workout time correctly with defaults', () {
        const config = WorkoutConfig();
        // 10 sets * 20 seconds + 9 rest periods * 4 seconds = 200 + 36 = 236
        expect(config.totalWorkoutSeconds, equals(236));
      });

      test('calculates correctly with custom values', () {
        const config = WorkoutConfig(
          secondsPerSet: 30,
          numberOfSets: 5,
          restBetweenSets: 15,
        );
        // 5 sets * 30 seconds + 4 rest periods * 15 seconds = 150 + 60 = 210
        expect(config.totalWorkoutSeconds, equals(210));
      });

      test('handles single set workout', () {
        const config = WorkoutConfig(
          secondsPerSet: 60,
          numberOfSets: 1,
          restBetweenSets: 30,
        );
        // 1 set * 60 seconds + 0 rest periods = 60
        expect(config.totalWorkoutSeconds, equals(60));
      });
    });

    group('totalWorkoutDuration', () {
      test('returns correct Duration', () {
        const config = WorkoutConfig();
        expect(config.totalWorkoutDuration, equals(const Duration(seconds: 236)));
      });

      test('returns correct Duration for custom config', () {
        const config = WorkoutConfig(
          secondsPerSet: 60,
          numberOfSets: 3,
          restBetweenSets: 30,
        );
        // 3 * 60 + 2 * 30 = 180 + 60 = 240
        expect(config.totalWorkoutDuration, equals(const Duration(seconds: 240)));
      });
    });

    group('formattedDuration', () {
      test('formats duration correctly for default config', () {
        const config = WorkoutConfig();
        // 236 seconds = 3 minutes 56 seconds
        expect(config.formattedDuration, equals('3:56'));
      });

      test('formats duration with leading zero for seconds', () {
        const config = WorkoutConfig(
          secondsPerSet: 60,
          numberOfSets: 2,
          restBetweenSets: 5,
        );
        // 2 * 60 + 1 * 5 = 125 seconds = 2 minutes 5 seconds
        expect(config.formattedDuration, equals('2:05'));
      });

      test('formats short durations correctly', () {
        const config = WorkoutConfig(
          secondsPerSet: 10,
          numberOfSets: 1,
          restBetweenSets: 0,
        );
        // 10 seconds = 0 minutes 10 seconds
        expect(config.formattedDuration, equals('0:10'));
      });

      test('formats exact minute durations correctly', () {
        const config = WorkoutConfig(
          secondsPerSet: 30,
          numberOfSets: 4,
          restBetweenSets: 0,
        );
        // 4 * 30 = 120 seconds = 2 minutes 0 seconds
        expect(config.formattedDuration, equals('2:00'));
      });
    });
  });
}
