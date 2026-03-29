import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:burpeebata/models/workout.dart';
import 'package:burpeebata/models/workout_template.dart';
import 'package:burpeebata/models/burpee_type.dart';
import 'package:burpeebata/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService - Workout Templates', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await StorageService.clearAllTemplates();
    });

    group('saveWorkoutTemplate', () {
      test('saves a new template successfully', () async {
        final template = WorkoutTemplate(
          id: 'template-1',
          name: 'Morning Burn',
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 10,
          secondsPerSet: 20,
          numberOfSets: 8,
          restBetweenSets: 10,
          initialCountdown: 10,
        );

        await StorageService.saveWorkoutTemplate(template);

        final templates = await StorageService.getWorkoutTemplates();
        expect(templates.length, equals(1));
        expect(templates.first.id, equals('template-1'));
        expect(templates.first.name, equals('Morning Burn'));
      });

      test('saves multiple templates', () async {
        final template1 = WorkoutTemplate(
          id: 'template-1',
          name: 'Morning Burn',
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 10,
          secondsPerSet: 20,
          numberOfSets: 8,
          restBetweenSets: 10,
          initialCountdown: 10,
        );

        final template2 = WorkoutTemplate(
          id: 'template-2',
          name: 'Evening Session',
          burpeeType: BurpeeType.navySeal,
          repsPerSet: 5,
          secondsPerSet: 15,
          numberOfSets: 12,
          restBetweenSets: 5,
          initialCountdown: 5,
        );

        await StorageService.saveWorkoutTemplate(template1);
        await StorageService.saveWorkoutTemplate(template2);

        final templates = await StorageService.getWorkoutTemplates();
        expect(templates.length, equals(2));
      });

      test('updates existing template with same id', () async {
        final original = WorkoutTemplate(
          id: 'template-1',
          name: 'Original Name',
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 10,
          secondsPerSet: 20,
          numberOfSets: 8,
          restBetweenSets: 10,
          initialCountdown: 10,
        );

        await StorageService.saveWorkoutTemplate(original);

        final updated = original.copyWith(name: 'Updated Name');
        await StorageService.saveWorkoutTemplate(updated);

        final templates = await StorageService.getWorkoutTemplates();
        expect(templates.length, equals(1));
        expect(templates.first.name, equals('Updated Name'));
      });
    });

    group('getWorkoutTemplates', () {
      test('returns empty list when no templates saved', () async {
        final templates = await StorageService.getWorkoutTemplates();
        expect(templates, isEmpty);
      });

      test('returns all saved templates', () async {
        final template1 = WorkoutTemplate(
          id: 'template-1',
          name: 'Template 1',
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 10,
          secondsPerSet: 20,
          numberOfSets: 8,
          restBetweenSets: 10,
          initialCountdown: 10,
        );

        final template2 = WorkoutTemplate(
          id: 'template-2',
          name: 'Template 2',
          burpeeType: BurpeeType.navySeal,
          repsPerSet: 5,
          secondsPerSet: 15,
          numberOfSets: 12,
          restBetweenSets: 5,
          initialCountdown: 5,
        );

        await StorageService.saveWorkoutTemplate(template1);
        await StorageService.saveWorkoutTemplate(template2);

        final templates = await StorageService.getWorkoutTemplates();
        expect(templates.length, equals(2));

        final ids = templates.map((t) => t.id).toSet();
        expect(ids.contains('template-1'), isTrue);
        expect(ids.contains('template-2'), isTrue);
      });

      test('returns templates sorted by createdAt descending', () async {
        final older = WorkoutTemplate(
          id: 'template-1',
          name: 'Older Template',
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 10,
          secondsPerSet: 20,
          numberOfSets: 8,
          restBetweenSets: 10,
          initialCountdown: 10,
          createdAt: DateTime(2024, 1, 1),
        );

        final newer = WorkoutTemplate(
          id: 'template-2',
          name: 'Newer Template',
          burpeeType: BurpeeType.navySeal,
          repsPerSet: 5,
          secondsPerSet: 15,
          numberOfSets: 12,
          restBetweenSets: 5,
          initialCountdown: 5,
          createdAt: DateTime(2024, 2, 1),
        );

        await StorageService.saveWorkoutTemplate(older);
        await StorageService.saveWorkoutTemplate(newer);

        final templates = await StorageService.getWorkoutTemplates();
        expect(templates.first.id, equals('template-2'));
        expect(templates.last.id, equals('template-1'));
      });
    });

    group('getWorkoutTemplate', () {
      test('returns template by id', () async {
        final template = WorkoutTemplate(
          id: 'template-1',
          name: 'Test Template',
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 10,
          secondsPerSet: 20,
          numberOfSets: 8,
          restBetweenSets: 10,
          initialCountdown: 10,
        );

        await StorageService.saveWorkoutTemplate(template);

        final retrieved = await StorageService.getWorkoutTemplate('template-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('template-1'));
        expect(retrieved.name, equals('Test Template'));
      });

      test('returns null when template not found', () async {
        final retrieved =
            await StorageService.getWorkoutTemplate('nonexistent-id');
        expect(retrieved, isNull);
      });
    });

    group('deleteWorkoutTemplate', () {
      test('deletes template by id', () async {
        final template1 = WorkoutTemplate(
          id: 'template-1',
          name: 'Template 1',
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 10,
          secondsPerSet: 20,
          numberOfSets: 8,
          restBetweenSets: 10,
          initialCountdown: 10,
        );

        final template2 = WorkoutTemplate(
          id: 'template-2',
          name: 'Template 2',
          burpeeType: BurpeeType.navySeal,
          repsPerSet: 5,
          secondsPerSet: 15,
          numberOfSets: 12,
          restBetweenSets: 5,
          initialCountdown: 5,
        );

        await StorageService.saveWorkoutTemplate(template1);
        await StorageService.saveWorkoutTemplate(template2);

        await StorageService.deleteWorkoutTemplate('template-1');

        final templates = await StorageService.getWorkoutTemplates();
        expect(templates.length, equals(1));
        expect(templates.first.id, equals('template-2'));
      });

      test('handles deletion of nonexistent template', () async {
        await StorageService.deleteWorkoutTemplate('nonexistent-id');
        final templates = await StorageService.getWorkoutTemplates();
        expect(templates, isEmpty);
      });
    });

    group('clearAllTemplates', () {
      test('removes all templates', () async {
        final template1 = WorkoutTemplate(
          id: 'template-1',
          name: 'Template 1',
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 10,
          secondsPerSet: 20,
          numberOfSets: 8,
          restBetweenSets: 10,
          initialCountdown: 10,
        );

        final template2 = WorkoutTemplate(
          id: 'template-2',
          name: 'Template 2',
          burpeeType: BurpeeType.navySeal,
          repsPerSet: 5,
          secondsPerSet: 15,
          numberOfSets: 12,
          restBetweenSets: 5,
          initialCountdown: 5,
        );

        await StorageService.saveWorkoutTemplate(template1);
        await StorageService.saveWorkoutTemplate(template2);

        await StorageService.clearAllTemplates();

        final templates = await StorageService.getWorkoutTemplates();
        expect(templates, isEmpty);
      });

      test('handles clearing when no templates exist', () async {
        await StorageService.clearAllTemplates();
        final templates = await StorageService.getWorkoutTemplates();
        expect(templates, isEmpty);
      });
    });

    group('DND during workout setting', () {
      test('defaults to false', () async {
        final isDndEnabled = await StorageService.isDndDuringWorkout();
        expect(isDndEnabled, isFalse);
      });

      test('can be enabled', () async {
        await StorageService.setDndDuringWorkout(true);

        final isDndEnabled = await StorageService.isDndDuringWorkout();
        expect(isDndEnabled, isTrue);
      });

      test('can be disabled', () async {
        await StorageService.setDndDuringWorkout(true);
        await StorageService.setDndDuringWorkout(false);

        final isDndEnabled = await StorageService.isDndDuringWorkout();
        expect(isDndEnabled, isFalse);
      });
    });

    group('template and workout isolation', () {
      test('templates and workouts are stored separately', () async {
        final template = WorkoutTemplate(
          id: 'template-1',
          name: 'Test Template',
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 10,
          secondsPerSet: 20,
          numberOfSets: 8,
          restBetweenSets: 10,
          initialCountdown: 10,
        );

        final workout = Workout(
          id: 'workout-1',
          date: DateTime.now(),
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 10,
          secondsPerSet: 20,
          numberOfSets: 8,
          restBetweenSets: 10,
        );

        await StorageService.saveWorkoutTemplate(template);
        await StorageService.saveWorkout(workout);

        final templates = await StorageService.getWorkoutTemplates();
        final workouts = await StorageService.getWorkouts();

        expect(templates.length, equals(1));
        expect(workouts.length, equals(1));

        await StorageService.clearAllTemplates();

        final templatesAfter = await StorageService.getWorkoutTemplates();
        final workoutsAfter = await StorageService.getWorkouts();

        expect(templatesAfter, isEmpty);
        expect(workoutsAfter.length, equals(1));
      });
    });
  });
}
