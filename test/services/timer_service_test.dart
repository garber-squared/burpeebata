import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:burpeebata/services/timer_service.dart';
import 'package:burpeebata/services/audio_service.dart';
import 'package:burpeebata/models/workout_config.dart';

import 'timer_service_test.mocks.dart';

@GenerateMocks([AudioService])
void main() {
  group('TimerService', () {
    late TimerService timerService;
    late MockAudioService mockAudioService;

    setUp(() {
      mockAudioService = MockAudioService();

      when(mockAudioService.init()).thenAnswer((_) async {});
      when(mockAudioService.playCountdownBeep(secondsRemaining: anyNamed('secondsRemaining'))).thenAnswer((_) async {});
      when(mockAudioService.playWorkStart()).thenAnswer((_) async {});
      when(mockAudioService.playRestStart()).thenAnswer((_) async {});
      when(mockAudioService.playPhaseComplete()).thenAnswer((_) async {});
      when(mockAudioService.playRepTick()).thenAnswer((_) async {});

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
        expect(timerService.currentSeconds, equals(0.0));
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

      test('sets countdown seconds to configured initialCountdown', () async {
        const config = WorkoutConfig();

        await timerService.startWorkout(config);

        expect(timerService.currentSeconds, equals(10.0));
      });

      test('sets countdown seconds to custom initialCountdown', () async {
        const config = WorkoutConfig(initialCountdown: 5);

        await timerService.startWorkout(config);

        expect(timerService.currentSeconds, equals(5.0));
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

        // At start of countdown (10 seconds remaining out of 10)
        // progress = 1 - (10/10) = 0
        expect(timerService.progress, equals(0));
      });
    });

    group('stop', () {
      test('cancels timer and resets state', () async {
        const config = WorkoutConfig();
        await timerService.startWorkout(config);

        timerService.stop();

        expect(timerService.state, equals(TimerState.idle));
        expect(timerService.currentSeconds, equals(0.0));
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
      test('countdown plays beep only in last 3 seconds', () {
        fakeAsync((async) {
          const config = WorkoutConfig(initialCountdown: 5);
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Fast-forward 1 second (5 -> 4, no beep yet)
          async.elapse(const Duration(seconds: 1));
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: anyNamed('secondsRemaining')));

          // At 2 seconds elapsed (5 -> 4 -> 3), beep should play
          async.elapse(const Duration(seconds: 1));
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 3)).called(1);

          // At 3 seconds elapsed (3 -> 2), another beep
          async.elapse(const Duration(seconds: 1));
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 2)).called(1);
        });
      });

      test('initial countdown with default 10 seconds plays beep in last 3', () {
        fakeAsync((async) {
          const config = WorkoutConfig();
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Fast-forward past first 6 seconds (no beeps yet, at 4 seconds remaining)
          async.elapse(const Duration(seconds: 6));
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: anyNamed('secondsRemaining')));

          // At 7 seconds elapsed (10 -> ... -> 3), beep should play
          async.elapse(const Duration(seconds: 1));
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 3)).called(1);

          // Continue to 2 seconds remaining
          async.elapse(const Duration(seconds: 1));
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 2)).called(1);

          // Continue to 1 second remaining
          async.elapse(const Duration(seconds: 1));
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 1)).called(1);
        });
      });
    });

    group('currentRep calculation', () {
      test('returns 0 when not in work state', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            repsPerSet: 5,
            secondsPerSet: 20,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // In countdown state
          expect(timerService.state, equals(TimerState.countdown));
          expect(timerService.currentRep, equals(0));
        });
      });

      test('returns 0 when repsPerSet is 0', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            repsPerSet: 0,
            secondsPerSet: 20,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Even if we could get to work state, should return 0
          expect(timerService.currentRep, equals(0));
        });
      });

      test('calculates rep 1 at start of work period', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            repsPerSet: 5,
            secondsPerSet: 20,
            numberOfSets: 1,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) to start work
          async.elapse(const Duration(seconds: 3));

          expect(timerService.state, equals(TimerState.work));
          // At start of 20 seconds, elapsed = 0, rep should be 1
          expect(timerService.currentRep, equals(1));
        });
      });

      test('calculates correct rep with even division', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            repsPerSet: 5,
            secondsPerSet: 20,
            numberOfSets: 1,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + 4 seconds of work
          // 20s / 5 reps = 4s per rep
          // At 4s elapsed, should be on rep 2
          async.elapse(const Duration(seconds: 7));

          expect(timerService.state, equals(TimerState.work));
          expect(timerService.currentRep, equals(2));
        });
      });

      test('clamps to max reps at end of work period', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            repsPerSet: 5,
            secondsPerSet: 20,
            numberOfSets: 1,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + 19 seconds of work (near end)
          async.elapse(const Duration(seconds: 22));

          expect(timerService.state, equals(TimerState.work));
          expect(timerService.currentRep, equals(5));
        });
      });

      test('handles repsPerSet of 1', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            repsPerSet: 1,
            secondsPerSet: 10,
            numberOfSets: 1,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown to start work
          async.elapse(const Duration(seconds: 3));

          expect(timerService.state, equals(TimerState.work));
          expect(timerService.currentRep, equals(1));
        });
      });

      test('handles uneven division', () {
        fakeAsync((async) {
          // 20s / 3 reps = 6.67s per rep
          const config = WorkoutConfig(
            repsPerSet: 3,
            secondsPerSet: 20,
            numberOfSets: 1,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + 7 seconds of work
          // 7 / 6.67 = 1.05, floor + 1 = 2
          async.elapse(const Duration(seconds: 10));

          expect(timerService.state, equals(TimerState.work));
          expect(timerService.currentRep, equals(2));
        });
      });
    });

    group('rep tick sound on rep change', () {
      test('does not play rep tick at start of work (rep 1)', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            repsPerSet: 5,
            secondsPerSet: 20,
            numberOfSets: 1,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown to start work
          async.elapse(const Duration(seconds: 3));

          // Should be in work state at rep 1
          expect(timerService.state, equals(TimerState.work));
          expect(timerService.currentRep, equals(1));

          // RepTick should not have been called yet
          verifyNever(mockAudioService.playRepTick());
        });
      });

      test('plays rep tick when rep changes from 1 to 2', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            repsPerSet: 5,
            secondsPerSet: 20,
            numberOfSets: 1,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + 4s work (first rep change at 4s)
          async.elapse(const Duration(seconds: 7));

          expect(timerService.state, equals(TimerState.work));
          expect(timerService.currentRep, equals(2));

          // RepTick should have been called once
          verify(mockAudioService.playRepTick()).called(1);
        });
      });

      test('plays rep tick on each rep change', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            repsPerSet: 5,
            secondsPerSet: 20,
            numberOfSets: 1,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + 12s work (3 rep changes at 4s, 8s, 12s)
          async.elapse(const Duration(seconds: 15));

          expect(timerService.state, equals(TimerState.work));
          expect(timerService.currentRep, equals(4));

          // RepTick should have been called 3 times (rep 2, 3, 4)
          verify(mockAudioService.playRepTick()).called(3);
        });
      });

      test('does not play rep tick when repsPerSet is 1', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            repsPerSet: 1,
            secondsPerSet: 10,
            numberOfSets: 1,
            initialCountdown: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown + some work time
          async.elapse(const Duration(seconds: 8));

          expect(timerService.state, equals(TimerState.work));

          // RepTick should never be called when there's only 1 rep
          verifyNever(mockAudioService.playRepTick());
        });
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

    group('elapsed time tracking', () {
      test('starts at 0', () {
        expect(timerService.elapsedWorkoutSeconds, equals(0));
      });

      test('remains 0 during countdown', () {
        fakeAsync((async) {
          const config = WorkoutConfig(initialCountdown: 5);
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse 4 seconds of countdown
          async.elapse(const Duration(seconds: 4));

          // Still in countdown state
          expect(timerService.state, equals(TimerState.countdown));
          // Elapsed time should still be 0 (countdown excluded)
          expect(timerService.elapsedWorkoutSeconds, equals(0));
        });
      });

      test('starts counting after countdown completes', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 20,
            numberOfSets: 1,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + a tiny bit more to ensure all ticks process
          async.elapse(const Duration(seconds: 3, milliseconds: 10));
          async.flushTimers();

          // Now in work state
          expect(timerService.state, equals(TimerState.work));
          // Elapsed should still be 0 at exact transition
          expect(timerService.elapsedWorkoutSeconds, equals(0));

          // Elapse 1 more second of work
          async.elapse(const Duration(seconds: 1));
          async.flushTimers();

          // Now elapsed should be 1
          expect(timerService.elapsedWorkoutSeconds, equals(1));
        });
      });

      test('continues counting through work periods', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 1,
            restBetweenSets: 0,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown + 5 seconds of work
          async.elapse(const Duration(seconds: 8));

          expect(timerService.state, equals(TimerState.work));
          expect(timerService.elapsedWorkoutSeconds, equals(5));
        });
      });

      test('continues counting through rest periods', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 5,
            numberOfSets: 2,
            restBetweenSets: 4,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + first work period (5s) + 2 seconds of rest
          async.elapse(const Duration(seconds: 10));

          expect(timerService.state, equals(TimerState.rest));
          // Should have counted: 5s work + 2s rest = 7s total
          expect(timerService.elapsedWorkoutSeconds, equals(7));
        });
      });

      test('tracks complete workout with multiple sets', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 3,
            restBetweenSets: 5,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Total workout time (excluding countdown):
          // 3 work periods * 10s = 30s
          // 2 rest periods * 5s = 10s
          // Total = 40s

          // Elapse countdown (3s) + full workout (40s) + extra time to process final tick
          async.elapse(const Duration(seconds: 43, milliseconds: 50));
          async.flushTimers();

          expect(timerService.state, equals(TimerState.finished));
          expect(timerService.elapsedWorkoutSeconds, equals(40));
        });
      });

      test('resets to 0 on stop', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 20,
            numberOfSets: 1,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse some time
          async.elapse(const Duration(seconds: 10));

          // Should have some elapsed time
          expect(timerService.elapsedWorkoutSeconds, greaterThan(0));

          // Stop the workout
          timerService.stop();

          // Elapsed time should reset
          expect(timerService.elapsedWorkoutSeconds, equals(0));
        });
      });

      test('does not count time during pause', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 20,
            numberOfSets: 1,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown + 5 seconds of work
          async.elapse(const Duration(seconds: 8));

          final elapsedBeforePause = timerService.elapsedWorkoutSeconds;
          expect(elapsedBeforePause, equals(5));

          // Pause the timer
          timerService.pause();

          // Elapse more time while paused
          async.elapse(const Duration(seconds: 10));

          // Elapsed time should not change during pause
          expect(timerService.elapsedWorkoutSeconds, equals(elapsedBeforePause));
        });
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
