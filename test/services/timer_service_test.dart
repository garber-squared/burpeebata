import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:burpeebata/services/timer_service.dart';
import 'package:burpeebata/services/audio_service.dart';
import 'package:burpeebata/models/workout_config.dart';
import 'package:burpeebata/models/burpee_type.dart';

import 'timer_service_test.mocks.dart';

@GenerateMocks([AudioService])
void main() {
  group('TimerService', () {
    late TimerService timerService;
    late MockAudioService mockAudioService;

    setUp(() {
      mockAudioService = MockAudioService();

      when(mockAudioService.init()).thenAnswer((_) async {});
      when(mockAudioService.playCountdownBeep()).thenAnswer((_) async {});
      when(mockAudioService.playWhistle()).thenAnswer((_) async {});
      when(mockAudioService.playBell()).thenAnswer((_) async {});
      when(mockAudioService.playPing()).thenAnswer((_) async {});

      timerService = TimerService(audioService: mockAudioService);
    });

    tearDown(() {
      timerService.dispose();
    });

    group('initial state', () {
      test('starts in idle state', () {
        expect(timerService.state, equals(TimerState.idle));
      });

      test('currentSeconds is 0', () {
        expect(timerService.currentSeconds, equals(0));
      });

      test('currentSet is 0', () {
        expect(timerService.currentSet, equals(0));
      });

      test('isRunning is false', () {
        expect(timerService.isRunning, equals(false));
      });

      test('progress is 0', () {
        expect(timerService.progress, equals(0));
      });

      test('completedSets is 0', () {
        expect(timerService.completedSets, equals(0));
      });

      test('currentRep is 0', () {
        expect(timerService.currentRep, equals(0));
      });

      test('repsPerSet is 0', () {
        expect(timerService.repsPerSet, equals(0));
      });
    });

    group('startWorkout', () {
      test('initializes audio service', () async {
        const config = WorkoutConfig();

        await timerService.startWorkout(config);

        verify(mockAudioService.init()).called(1);
      });

      test('sets up workout parameters from config', () async {
        const config = WorkoutConfig(
          numberOfSets: 5,
          secondsPerSet: 30,
          restBetweenSets: 15,
          repsPerSet: 6,
        );

        await timerService.startWorkout(config);

        expect(timerService.totalSets, equals(5));
        expect(timerService.workSeconds, equals(30));
        expect(timerService.restSeconds, equals(15));
        expect(timerService.repsPerSet, equals(6));
        expect(timerService.currentSet, equals(1));
      });

      test('transitions to countdown state', () async {
        const config = WorkoutConfig();

        await timerService.startWorkout(config);

        expect(timerService.state, equals(TimerState.countdown));
      });

      test('sets countdown seconds to 3', () async {
        const config = WorkoutConfig();

        await timerService.startWorkout(config);

        expect(timerService.currentSeconds, equals(3));
      });

      test('plays countdown beep on start', () async {
        const config = WorkoutConfig();

        await timerService.startWorkout(config);

        verify(mockAudioService.playCountdownBeep()).called(1);
      });
    });

    group('isRunning', () {
      test('returns true during countdown', () async {
        const config = WorkoutConfig();
        await timerService.startWorkout(config);

        expect(timerService.isRunning, equals(true));
      });

      test('returns false when idle', () {
        expect(timerService.isRunning, equals(false));
      });
    });

    group('progress calculation', () {
      test('returns 0 when idle', () {
        expect(timerService.progress, equals(0));
      });

      test('calculates progress during countdown', () async {
        const config = WorkoutConfig();
        await timerService.startWorkout(config);

        // At start of countdown (3 seconds remaining out of 3)
        // progress = 1 - (3/3) = 0
        expect(timerService.progress, equals(0));
      });
    });

    group('stop', () {
      test('cancels timer and resets state', () async {
        const config = WorkoutConfig();
        await timerService.startWorkout(config);

        timerService.stop();

        expect(timerService.state, equals(TimerState.idle));
        expect(timerService.currentSeconds, equals(0));
        expect(timerService.currentSet, equals(0));
        expect(timerService.isRunning, equals(false));
      });
    });

    group('pause and resume', () {
      test('pause stops the timer', () async {
        const config = WorkoutConfig();
        await timerService.startWorkout(config);

        timerService.pause();

        // Timer should be paused but state remains
        expect(timerService.state, equals(TimerState.countdown));
        expect(timerService.isRunning, equals(true));
      });

      test('resume restarts the timer when running', () async {
        const config = WorkoutConfig();
        await timerService.startWorkout(config);

        timerService.pause();
        timerService.resume();

        expect(timerService.isRunning, equals(true));
      });
    });

    group('completedSets', () {
      test('returns 0 when idle', () {
        expect(timerService.completedSets, equals(0));
      });

      test('returns currentSet - 1 during countdown', () async {
        const config = WorkoutConfig();
        await timerService.startWorkout(config);

        // During countdown for set 1, 0 sets completed
        expect(timerService.completedSets, equals(0));
      });
    });

    group('getters', () {
      test('totalSets returns configured value after start', () async {
        const config = WorkoutConfig(numberOfSets: 10);
        await timerService.startWorkout(config);

        expect(timerService.totalSets, equals(10));
      });

      test('workSeconds returns configured value after start', () async {
        const config = WorkoutConfig(secondsPerSet: 45);
        await timerService.startWorkout(config);

        expect(timerService.workSeconds, equals(45));
      });

      test('restSeconds returns configured value after start', () async {
        const config = WorkoutConfig(restBetweenSets: 20);
        await timerService.startWorkout(config);

        expect(timerService.restSeconds, equals(20));
      });
    });

    group('timer tick simulation', () {
      test('countdown decrements and plays beep each second', () async {
        const config = WorkoutConfig();
        await timerService.startWorkout(config);

        // Fast-forward time to simulate tick
        await Future.delayed(const Duration(milliseconds: 1100));

        // Should have played additional beep
        verify(mockAudioService.playCountdownBeep()).called(greaterThan(1));
      });
    });

    group('currentRep calculation', () {
      test('returns 0 when not in work state', () async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
        );
        await timerService.startWorkout(config);

        // In countdown state
        expect(timerService.state, equals(TimerState.countdown));
        expect(timerService.currentRep, equals(0));
      });

      test('returns 0 when repsPerSet is 0', () async {
        const config = WorkoutConfig(
          repsPerSet: 0,
          secondsPerSet: 20,
        );
        await timerService.startWorkout(config);

        // Even if we could get to work state, should return 0
        expect(timerService.currentRep, equals(0));
      });

      test('calculates rep 1 at start of work period', () async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 1,
        );
        await timerService.startWorkout(config);

        // Wait for countdown to finish and work to start
        await Future.delayed(const Duration(milliseconds: 3200));

        expect(timerService.state, equals(TimerState.work));
        // At start of 20 seconds, elapsed = 0, rep should be 1
        expect(timerService.currentRep, equals(1));
      });

      test('calculates correct rep with even division', () async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 1,
        );
        await timerService.startWorkout(config);

        // Wait for countdown (3s) + 4 seconds of work
        // 20s / 5 reps = 4s per rep
        // At 4s elapsed, should be on rep 2
        await Future.delayed(const Duration(milliseconds: 7200));

        expect(timerService.state, equals(TimerState.work));
        expect(timerService.currentRep, equals(2));
      });

      test('clamps to max reps at end of work period', () async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 1,
        );
        await timerService.startWorkout(config);

        // Wait for countdown (3s) + 19 seconds of work (near end)
        await Future.delayed(const Duration(milliseconds: 22200));

        expect(timerService.state, equals(TimerState.work));
        expect(timerService.currentRep, equals(5));
      });

      test('handles repsPerSet of 1', () async {
        const config = WorkoutConfig(
          repsPerSet: 1,
          secondsPerSet: 10,
          numberOfSets: 1,
        );
        await timerService.startWorkout(config);

        // Wait for countdown to finish
        await Future.delayed(const Duration(milliseconds: 3200));

        expect(timerService.state, equals(TimerState.work));
        expect(timerService.currentRep, equals(1));
      });

      test('handles uneven division', () async {
        // 20s / 3 reps = 6.67s per rep
        const config = WorkoutConfig(
          repsPerSet: 3,
          secondsPerSet: 20,
          numberOfSets: 1,
        );
        await timerService.startWorkout(config);

        // Wait for countdown (3s) + 7 seconds of work
        // 7 / 6.67 = 1.05, floor + 1 = 2
        await Future.delayed(const Duration(milliseconds: 10200));

        expect(timerService.state, equals(TimerState.work));
        expect(timerService.currentRep, equals(2));
      });
    });

    group('ping sound on rep change', () {
      test('does not play ping at start of work (rep 1)', () async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 1,
        );
        await timerService.startWorkout(config);

        // Wait for countdown to finish
        await Future.delayed(const Duration(milliseconds: 3200));

        // Should be in work state at rep 1
        expect(timerService.state, equals(TimerState.work));
        expect(timerService.currentRep, equals(1));

        // Ping should not have been called yet
        verifyNever(mockAudioService.playPing());
      });

      test('plays ping when rep changes from 1 to 2', () async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 1,
        );
        await timerService.startWorkout(config);

        // Wait for countdown (3s) + 4s work (first rep change at 4s)
        await Future.delayed(const Duration(milliseconds: 7200));

        expect(timerService.state, equals(TimerState.work));
        expect(timerService.currentRep, equals(2));

        // Ping should have been called once
        verify(mockAudioService.playPing()).called(1);
      });

      test('plays ping on each rep change', () async {
        const config = WorkoutConfig(
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 1,
        );
        await timerService.startWorkout(config);

        // Wait for countdown (3s) + 12s work (3 rep changes at 4s, 8s, 12s)
        await Future.delayed(const Duration(milliseconds: 15200));

        expect(timerService.state, equals(TimerState.work));
        expect(timerService.currentRep, equals(4));

        // Ping should have been called 3 times (rep 2, 3, 4)
        verify(mockAudioService.playPing()).called(3);
      });

      test('does not play ping when repsPerSet is 1', () async {
        const config = WorkoutConfig(
          repsPerSet: 1,
          secondsPerSet: 10,
          numberOfSets: 1,
        );
        await timerService.startWorkout(config);

        // Wait for countdown + some work time
        await Future.delayed(const Duration(milliseconds: 8200));

        expect(timerService.state, equals(TimerState.work));

        // Ping should never be called when there's only 1 rep
        verifyNever(mockAudioService.playPing());
      });
    });

    group('notifyListeners', () {
      test('notifies listeners on state change', () async {
        int notificationCount = 0;
        timerService.addListener(() {
          notificationCount++;
        });

        const config = WorkoutConfig();
        await timerService.startWorkout(config);

        expect(notificationCount, greaterThan(0));
      });

      test('notifies listeners on stop', () async {
        const config = WorkoutConfig();
        await timerService.startWorkout(config);

        int notificationCount = 0;
        timerService.addListener(() {
          notificationCount++;
        });

        timerService.stop();

        expect(notificationCount, equals(1));
      });
    });
  });

  group('TimerState enum', () {
    test('has correct values', () {
      expect(TimerState.values.length, equals(5));
      expect(TimerState.values, contains(TimerState.idle));
      expect(TimerState.values, contains(TimerState.countdown));
      expect(TimerState.values, contains(TimerState.work));
      expect(TimerState.values, contains(TimerState.rest));
      expect(TimerState.values, contains(TimerState.finished));
    });
  });
}
