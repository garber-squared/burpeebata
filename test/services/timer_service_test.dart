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
      when(mockAudioService.playVictory()).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 0)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 1)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 2)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 3)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 4)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 5)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 10)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 15)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 20)).thenAnswer((_) async {});

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

          // Fast-forward 1.5 seconds (still at 4+ seconds remaining, no beep yet)
          async.elapse(const Duration(seconds: 1, milliseconds: 500));
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 3));

          // Elapse past 3 seconds remaining mark (tick fires at 2.99s remaining)
          async.elapse(const Duration(milliseconds: 600));
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 3)).called(1);

          // Elapse to 2 seconds remaining (tick fires at 1.99s remaining)
          async.elapse(const Duration(seconds: 1));
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 2)).called(1);
        });
      });

      test('initial countdown with default 10 seconds plays beep in last 3', () {
        fakeAsync((async) {
          const config = WorkoutConfig();
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Fast-forward past first 6.5 seconds (at 3.5 seconds remaining, no beep yet)
          async.elapse(const Duration(seconds: 6, milliseconds: 500));
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 3));

          // Elapse past 3 seconds remaining mark (tick fires at 2.99s remaining)
          async.elapse(const Duration(milliseconds: 600));
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

          // Elapse countdown (3s) + small buffer to transition to work
          async.elapse(const Duration(seconds: 3, milliseconds: 50));

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

          // Elapse countdown (3s) + 4 seconds of work + buffer
          // 20s / 5 reps = 4s per rep
          // At 4s elapsed, should be on rep 2
          async.elapse(const Duration(seconds: 7, milliseconds: 50));

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

          // Elapse countdown + buffer to start work
          async.elapse(const Duration(seconds: 3, milliseconds: 50));

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

          // Elapse countdown + buffer to start work
          async.elapse(const Duration(seconds: 3, milliseconds: 50));

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

          // Elapse countdown (3s) + 4s work (first rep change at 4s) + buffer
          async.elapse(const Duration(seconds: 7, milliseconds: 50));

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

          // Elapse countdown (3s) + 12s work (3 rep changes at 4s, 8s, 12s) + buffer
          async.elapse(const Duration(seconds: 15, milliseconds: 50));

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

          // Elapse countdown + some work time + buffer
          async.elapse(const Duration(seconds: 8, milliseconds: 50));

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
            restBetweenSets: 5, // Explicit rest to avoid any default issues
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + just enough buffer to transition to work
          // The tick fires at centiseconds % 100 == 99, which is after 10ms
          // So 15ms should be enough to transition but not trigger first elapsed tick
          async.elapse(const Duration(seconds: 3, milliseconds: 15));

          // Now in work state
          expect(timerService.state, equals(TimerState.work));
          // Elapsed should still be 0 (tick at 0.99s remaining hasn't fired yet)
          expect(timerService.elapsedWorkoutSeconds, equals(0));

          // Elapse almost 1 second more - tick fires at 0.99s remaining in work
          async.elapse(const Duration(milliseconds: 990));

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

  group('Short rest handling (Issue #53)', () {
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
      when(mockAudioService.playVictory()).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 0)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 1)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 2)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 3)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 4)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 5)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 10)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 15)).thenAnswer((_) async {});
      when(mockAudioService.playEndOfRest(restDuration: 20)).thenAnswer((_) async {});

      timerService = TimerService(audioService: mockAudioService);
    });

    tearDown(() {
      timerService.dispose();
    });

    group('rest = 0 seconds', () {
      test('skips rest phase entirely', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 0,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + first work period (10s) + small buffer for transition
          async.elapse(const Duration(seconds: 13, milliseconds: 50));

          // Should go directly to second work set, not rest
          expect(timerService.state, equals(TimerState.work));
          expect(timerService.currentSet, equals(2));

          // Rest start sound should never be called
          verifyNever(mockAudioService.playRestStart());
        });
      });

      test('plays end-of-rest countdown at 3 seconds remaining in work', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 0,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + 6.5 seconds of work (3.5 seconds remaining)
          // Not yet at 3 seconds remaining tick (which fires at 2.99s remaining)
          async.elapse(const Duration(seconds: 9, milliseconds: 500));
          verifyNever(mockAudioService.playEndOfRest(restDuration: 3));

          // Elapse past the 3 seconds remaining mark (tick fires at 2.99s remaining)
          async.elapse(const Duration(milliseconds: 600));
          verify(mockAudioService.playEndOfRest(restDuration: 3)).called(1);
        });
      });

      test('does not play phase complete bell', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 0,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + first work period (10s)
          async.elapse(const Duration(seconds: 13));

          // Phase complete should not be called for short rest
          verifyNever(mockAudioService.playPhaseComplete());
        });
      });
    });

    group('rest = 1 second', () {
      test('plays end-of-rest countdown at 2 seconds remaining in work', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 1,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + 7.5 seconds of work (2.5 seconds remaining)
          // Not yet at 2 seconds remaining tick (which fires at 1.99s remaining)
          async.elapse(const Duration(seconds: 10, milliseconds: 500));
          verifyNever(mockAudioService.playEndOfRest(restDuration: 3));

          // Elapse past the 2 seconds remaining mark (tick fires at 1.99s remaining)
          async.elapse(const Duration(milliseconds: 600));
          verify(mockAudioService.playEndOfRest(restDuration: 3)).called(1);
        });
      });

      test('does not play phase complete bell', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 1,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + first work period (10s)
          async.elapse(const Duration(seconds: 13));

          // Phase complete should not be called for short rest
          verifyNever(mockAudioService.playPhaseComplete());
        });
      });

      test('transitions to rest phase after work', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 1,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + first work period (10s) + a bit
          async.elapse(const Duration(seconds: 13, milliseconds: 50));

          expect(timerService.state, equals(TimerState.rest));
        });
      });

      test('does not double-play end-of-rest during rest phase', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 1,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse entire first set + rest
          async.elapse(const Duration(seconds: 14, milliseconds: 50));

          // Should only be called once (during work phase)
          verify(mockAudioService.playEndOfRest(restDuration: 3)).called(1);
        });
      });
    });

    group('rest = 2 seconds', () {
      test('plays end-of-rest countdown at 1 second remaining in work', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 2,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + 8.5 seconds of work (1.5 seconds remaining)
          // Not yet at 1 second remaining tick (which fires at 0.99s remaining)
          async.elapse(const Duration(seconds: 11, milliseconds: 500));
          verifyNever(mockAudioService.playEndOfRest(restDuration: 3));

          // Elapse past the 1 second remaining mark (tick fires at 0.99s remaining)
          async.elapse(const Duration(milliseconds: 600));
          verify(mockAudioService.playEndOfRest(restDuration: 3)).called(1);
        });
      });

      test('does not play phase complete bell', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 2,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + first work period (10s)
          async.elapse(const Duration(seconds: 13));

          // Phase complete should not be called for short rest
          verifyNever(mockAudioService.playPhaseComplete());
        });
      });
    });

    group('rest = 3 seconds', () {
      test('plays end-of-rest countdown during rest phase (not work)', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + first work period (10s)
          async.elapse(const Duration(seconds: 13));

          // End of rest should not be played during work when rest >= 3
          verifyNever(mockAudioService.playEndOfRest(restDuration: 3));

          // Elapse into rest phase and past 3 seconds remaining (tick fires at 2.99s)
          async.elapse(const Duration(milliseconds: 110));
          expect(timerService.state, equals(TimerState.rest));

          // Now end of rest should play (at 3 seconds remaining in rest, which is immediately for 3s rest)
          verify(mockAudioService.playEndOfRest(restDuration: 3)).called(1);
        });
      });

      test('plays phase complete bell', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 3,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + first work period (10s) + a bit
          async.elapse(const Duration(seconds: 13, milliseconds: 50));

          // Phase complete should be called for rest >= 3
          verify(mockAudioService.playPhaseComplete()).called(1);
        });
      });
    });

    group('rest > 3 seconds (normal case)', () {
      test('plays phase complete bell at end of work', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 5,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + first work period (10s) + a bit
          async.elapse(const Duration(seconds: 13, milliseconds: 50));

          verify(mockAudioService.playPhaseComplete()).called(1);
        });
      });

      test('plays end-of-rest at 3 seconds remaining in rest', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 5,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + work (10s) + 1.5 seconds of rest (3.5 remaining)
          // Not yet at 3 seconds remaining tick
          async.elapse(const Duration(seconds: 14, milliseconds: 500));
          verifyNever(mockAudioService.playEndOfRest(restDuration: 5));

          // Elapse past the 3 seconds remaining mark (tick fires at 2.99s remaining)
          async.elapse(const Duration(milliseconds: 600));
          verify(mockAudioService.playEndOfRest(restDuration: 5)).called(1);
        });
      });

      test('does not play end-of-rest during work', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 5,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + first work period (10s)
          async.elapse(const Duration(seconds: 13));

          // End of rest should not be called during work when rest > 3
          verifyNever(mockAudioService.playEndOfRest(restDuration: 5));
        });
      });
    });

    group('multiple sets with short rest', () {
      test('plays end-of-rest during each work phase except last', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 3,
            restBetweenSets: 1,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Run the entire workout:
          // - Countdown: 3s
          // - Work 1: 10s, Rest 1: 1s
          // - Work 2: 10s, Rest 2: 1s
          // - Work 3: 10s (no rest after last set)
          // Total: 3 + 10 + 1 + 10 + 1 + 10 = 35s + buffer
          async.elapse(const Duration(seconds: 36));

          expect(timerService.state, equals(TimerState.finished));

          // End-of-rest should be called exactly twice:
          // - Once during work 1 (for rest 1)
          // - Once during work 2 (for rest 2)
          // - NOT during work 3 (it's the last set, no rest follows)
          verify(mockAudioService.playEndOfRest(restDuration: 3)).called(2);
        });
      });
    });

    group('countdown beeps during work with short rest', () {
      test('does NOT play countdown beeps during work when rest < 3 and more sets remain', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 1,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) - countdown beeps play during countdown
          async.elapse(const Duration(seconds: 3, milliseconds: 50));

          // Reset mock to only count beeps during work phase
          clearInteractions(mockAudioService);

          // Elapse through the first work period (10s)
          // The last 3 seconds should NOT play countdown beeps because rest < 3
          async.elapse(const Duration(seconds: 10));

          // Countdown beeps should NOT be played during work when rest < 3
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 3));
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 2));
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 1));
        });
      });

      test('DOES play countdown beeps during work on last set even with short rest configured', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 1,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s) + work 1 (10s) + rest 1 (1s)
          async.elapse(const Duration(seconds: 14, milliseconds: 50));

          // Now in second (last) work set
          expect(timerService.state, equals(TimerState.work));
          expect(timerService.currentSet, equals(2));

          // Reset mock to only count beeps during last work phase
          clearInteractions(mockAudioService);

          // Elapse through the last work period
          async.elapse(const Duration(seconds: 10));

          // Countdown beeps SHOULD be played during last set (no rest follows)
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 3)).called(1);
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 2)).called(1);
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 1)).called(1);
        });
      });

      test('DOES play countdown beeps during work when rest >= 3', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 5,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s)
          async.elapse(const Duration(seconds: 3, milliseconds: 50));

          // Reset mock to only count beeps during work phase
          clearInteractions(mockAudioService);

          // Elapse through the first work period (10s)
          async.elapse(const Duration(seconds: 10));

          // Countdown beeps SHOULD be played during work when rest >= 3
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 3)).called(1);
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 2)).called(1);
          verify(mockAudioService.playCountdownBeep(secondsRemaining: 1)).called(1);
        });
      });

      test('rest = 0: no countdown beeps during work (end-of-rest audio provides countdown)', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 0,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s)
          async.elapse(const Duration(seconds: 3, milliseconds: 50));

          // Reset mock to only count beeps during work phase
          clearInteractions(mockAudioService);

          // Elapse through the first work period (10s)
          async.elapse(const Duration(seconds: 10));

          // Countdown beeps should NOT be played during work when rest = 0
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 3));
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 2));
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 1));
        });
      });

      test('rest = 2: no countdown beeps during work (end-of-rest audio provides countdown)', () {
        fakeAsync((async) {
          const config = WorkoutConfig(
            initialCountdown: 3,
            secondsPerSet: 10,
            numberOfSets: 2,
            restBetweenSets: 2,
          );
          timerService.startWorkout(config);
          async.flushMicrotasks();

          // Elapse countdown (3s)
          async.elapse(const Duration(seconds: 3, milliseconds: 50));

          // Reset mock to only count beeps during work phase
          clearInteractions(mockAudioService);

          // Elapse through the first work period (10s)
          async.elapse(const Duration(seconds: 10));

          // Countdown beeps should NOT be played during work when rest = 2
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 3));
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 2));
          verifyNever(mockAudioService.playCountdownBeep(secondsRemaining: 1));
        });
      });
    });
  });
}
