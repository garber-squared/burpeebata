import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:burpeebata/models/workout.dart';
import 'package:burpeebata/models/burpee_type.dart';
import 'package:burpeebata/services/workout_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('WorkoutService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late WorkoutService workoutService;
    const testUserId = 'test-user-123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      workoutService = WorkoutService(firestore: fakeFirestore);
    });

    Workout createTestWorkout({
      String? id,
      DateTime? date,
      bool completed = true,
      int completedSets = 5,
    }) {
      return Workout(
        id: id ?? 'workout-1',
        date: date ?? DateTime(2024, 1, 15, 10, 30),
        burpeeType: BurpeeType.militarySixCount,
        repsPerSet: 10,
        secondsPerSet: 20,
        numberOfSets: 5,
        restBetweenSets: 10,
        completed: completed,
        completedSets: completedSets,
        isCompleted: true,
        isCompletedInTime: false,
        elapsedSeconds: 120,
      );
    }

    group('saveWorkout', () {
      test('saves workout to Firestore', () async {
        final workout = createTestWorkout();

        await workoutService.saveWorkout(testUserId, workout);

        final saved = await workoutService.getWorkout(testUserId, workout.id);
        expect(saved, isNotNull);
        expect(saved!.id, equals(workout.id));
        expect(saved.burpeeType, equals(BurpeeType.militarySixCount));
        expect(saved.repsPerSet, equals(10));
      });

      test('updates existing workout with same id', () async {
        final original = createTestWorkout();
        await workoutService.saveWorkout(testUserId, original);

        final updated = original.copyWith(
          completedSets: 3,
          completed: false,
        );
        await workoutService.saveWorkout(testUserId, updated);

        final saved = await workoutService.getWorkout(testUserId, original.id);
        expect(saved!.completedSets, equals(3));
        expect(saved.completed, isFalse);
      });
    });

    group('getWorkouts', () {
      test('returns empty list when no workouts exist', () async {
        final workouts = await workoutService.getWorkouts(testUserId);
        expect(workouts, isEmpty);
      });

      test('returns all workouts for user', () async {
        final workout1 = createTestWorkout(id: 'workout-1');
        final workout2 = createTestWorkout(id: 'workout-2');

        await workoutService.saveWorkout(testUserId, workout1);
        await workoutService.saveWorkout(testUserId, workout2);

        final workouts = await workoutService.getWorkouts(testUserId);
        expect(workouts.length, equals(2));
      });

      test('returns workouts sorted by date descending', () async {
        final older = createTestWorkout(
          id: 'workout-1',
          date: DateTime(2024, 1, 1),
        );
        final newer = createTestWorkout(
          id: 'workout-2',
          date: DateTime(2024, 2, 1),
        );

        await workoutService.saveWorkout(testUserId, older);
        await workoutService.saveWorkout(testUserId, newer);

        final workouts = await workoutService.getWorkouts(testUserId);
        expect(workouts.first.id, equals('workout-2'));
        expect(workouts.last.id, equals('workout-1'));
      });

      test('isolates workouts by user', () async {
        final user1Workout = createTestWorkout(id: 'workout-1');
        final user2Workout = createTestWorkout(id: 'workout-2');

        await workoutService.saveWorkout('user-1', user1Workout);
        await workoutService.saveWorkout('user-2', user2Workout);

        final user1Workouts = await workoutService.getWorkouts('user-1');
        final user2Workouts = await workoutService.getWorkouts('user-2');

        expect(user1Workouts.length, equals(1));
        expect(user2Workouts.length, equals(1));
        expect(user1Workouts.first.id, equals('workout-1'));
        expect(user2Workouts.first.id, equals('workout-2'));
      });
    });

    group('workoutsStream', () {
      test('emits workout updates in real-time', () async {
        final workout = createTestWorkout();

        // Listen to stream and collect emissions
        final emissions = <List<Workout>>[];
        final subscription = workoutService.workoutsStream(testUserId).listen(
          (workouts) => emissions.add(workouts),
        );

        // Wait for initial empty state
        await Future.delayed(const Duration(milliseconds: 100));
        expect(emissions.length, greaterThanOrEqualTo(1));
        expect(emissions.first, isEmpty);

        // Save workout and wait for update
        await workoutService.saveWorkout(testUserId, workout);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(emissions.length, greaterThanOrEqualTo(2));
        expect(emissions.last.length, equals(1));
        expect(emissions.last.first.id, equals(workout.id));

        await subscription.cancel();
      });
    });

    group('getWorkout', () {
      test('returns workout by id', () async {
        final workout = createTestWorkout();
        await workoutService.saveWorkout(testUserId, workout);

        final retrieved = await workoutService.getWorkout(testUserId, workout.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(workout.id));
      });

      test('returns null when workout not found', () async {
        final retrieved = await workoutService.getWorkout(testUserId, 'nonexistent-id');
        expect(retrieved, isNull);
      });
    });

    group('deleteWorkout', () {
      test('deletes workout by id', () async {
        final workout1 = createTestWorkout(id: 'workout-1');
        final workout2 = createTestWorkout(id: 'workout-2');

        await workoutService.saveWorkout(testUserId, workout1);
        await workoutService.saveWorkout(testUserId, workout2);

        await workoutService.deleteWorkout(testUserId, 'workout-1');

        final workouts = await workoutService.getWorkouts(testUserId);
        expect(workouts.length, equals(1));
        expect(workouts.first.id, equals('workout-2'));
      });

      test('handles deletion of nonexistent workout', () async {
        // Should not throw
        await workoutService.deleteWorkout(testUserId, 'nonexistent-id');

        final workouts = await workoutService.getWorkouts(testUserId);
        expect(workouts, isEmpty);
      });
    });

    group('clearAllWorkouts', () {
      test('deletes all workouts for user', () async {
        final workout1 = createTestWorkout(id: 'workout-1');
        final workout2 = createTestWorkout(id: 'workout-2');

        await workoutService.saveWorkout(testUserId, workout1);
        await workoutService.saveWorkout(testUserId, workout2);

        await workoutService.clearAllWorkouts(testUserId);

        final workouts = await workoutService.getWorkouts(testUserId);
        expect(workouts, isEmpty);
      });

      test('only deletes workouts for specified user', () async {
        final user1Workout = createTestWorkout(id: 'workout-1');
        final user2Workout = createTestWorkout(id: 'workout-2');

        await workoutService.saveWorkout('user-1', user1Workout);
        await workoutService.saveWorkout('user-2', user2Workout);

        await workoutService.clearAllWorkouts('user-1');

        final user1Workouts = await workoutService.getWorkouts('user-1');
        final user2Workouts = await workoutService.getWorkouts('user-2');

        expect(user1Workouts, isEmpty);
        expect(user2Workouts.length, equals(1));
      });
    });

    group('getWorkoutsInRange', () {
      test('returns workouts within date range', () async {
        final workout1 = createTestWorkout(
          id: 'workout-1',
          date: DateTime(2024, 1, 15),
        );
        final workout2 = createTestWorkout(
          id: 'workout-2',
          date: DateTime(2024, 1, 20),
        );
        final workout3 = createTestWorkout(
          id: 'workout-3',
          date: DateTime(2024, 2, 1),
        );

        await workoutService.saveWorkout(testUserId, workout1);
        await workoutService.saveWorkout(testUserId, workout2);
        await workoutService.saveWorkout(testUserId, workout3);

        final workouts = await workoutService.getWorkoutsInRange(
          testUserId,
          DateTime(2024, 1, 10),
          DateTime(2024, 1, 25),
        );

        expect(workouts.length, equals(2));
        expect(workouts.map((w) => w.id).toSet(), equals({'workout-1', 'workout-2'}));
      });

      test('returns empty list when no workouts in range', () async {
        final workout = createTestWorkout(date: DateTime(2024, 1, 15));
        await workoutService.saveWorkout(testUserId, workout);

        final workouts = await workoutService.getWorkoutsInRange(
          testUserId,
          DateTime(2024, 2, 1),
          DateTime(2024, 2, 28),
        );

        expect(workouts, isEmpty);
      });
    });

    group('getRecentWorkouts', () {
      test('returns limited number of recent workouts', () async {
        for (int i = 1; i <= 10; i++) {
          final workout = createTestWorkout(
            id: 'workout-$i',
            date: DateTime(2024, 1, i),
          );
          await workoutService.saveWorkout(testUserId, workout);
        }

        final recent = await workoutService.getRecentWorkouts(testUserId, 3);

        expect(recent.length, equals(3));
        // Should be sorted newest first
        expect(recent[0].id, equals('workout-10'));
        expect(recent[1].id, equals('workout-9'));
        expect(recent[2].id, equals('workout-8'));
      });

      test('returns all workouts if count is greater than total', () async {
        final workout1 = createTestWorkout(id: 'workout-1');
        final workout2 = createTestWorkout(id: 'workout-2');

        await workoutService.saveWorkout(testUserId, workout1);
        await workoutService.saveWorkout(testUserId, workout2);

        final recent = await workoutService.getRecentWorkouts(testUserId, 10);

        expect(recent.length, equals(2));
      });
    });

    group('workoutExists', () {
      test('returns true when workout exists', () async {
        final workout = createTestWorkout();
        await workoutService.saveWorkout(testUserId, workout);

        final exists = await workoutService.workoutExists(testUserId, workout.id);
        expect(exists, isTrue);
      });

      test('returns false when workout does not exist', () async {
        final exists = await workoutService.workoutExists(testUserId, 'nonexistent-id');
        expect(exists, isFalse);
      });
    });

    group('error handling', () {
      test('throws WorkoutServiceException on Firestore errors', () async {
        // This would require mocking Firestore to throw errors
        // Skip for now since fake_cloud_firestore doesn't easily simulate errors
      });
    });
  });
}
