import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import '../models/workout_template.dart';
import '../models/workout_config.dart';

class StorageService {
  static const String _workoutsKey = 'workouts';
  static const String _templatesKey = 'workout_templates';
  static const String _lastUsedConfigKey = 'last_used_config';
  static const String _powerUserModeKey = 'power_user_mode';

  static Future<void> saveWorkout(Workout workout) async {
    final prefs = await SharedPreferences.getInstance();
    final workouts = await getWorkouts();
    workouts.add(workout);

    final jsonList = workouts.map((w) => w.toJson()).toList();
    await prefs.setString(_workoutsKey, jsonEncode(jsonList));
  }

  static Future<List<Workout>> getWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_workoutsKey);

    if (jsonString == null) {
      return [];
    }

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => Workout.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> deleteWorkout(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final workouts = await getWorkouts();
    workouts.removeWhere((w) => w.id == id);

    final jsonList = workouts.map((w) => w.toJson()).toList();
    await prefs.setString(_workoutsKey, jsonEncode(jsonList));
  }

  static Future<void> clearAllWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workoutsKey);
  }

  // Workout Template methods
  static Future<void> saveWorkoutTemplate(WorkoutTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await getWorkoutTemplates();

    // Remove existing template with same id if present
    templates.removeWhere((t) => t.id == template.id);
    templates.add(template);

    final jsonList = templates.map((t) => t.toJson()).toList();
    await prefs.setString(_templatesKey, jsonEncode(jsonList));
  }

  static Future<List<WorkoutTemplate>> getWorkoutTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_templatesKey);

    if (jsonString == null) {
      return [];
    }

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => WorkoutTemplate.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<WorkoutTemplate?> getWorkoutTemplate(String id) async {
    final templates = await getWorkoutTemplates();
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteWorkoutTemplate(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await getWorkoutTemplates();
    templates.removeWhere((t) => t.id == id);

    final jsonList = templates.map((t) => t.toJson()).toList();
    await prefs.setString(_templatesKey, jsonEncode(jsonList));
  }

  static Future<void> clearAllTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_templatesKey);
  }

  // Last Used Configuration methods (Power User feature)
  /// Save the last-used workout configuration for quick access
  static Future<void> saveLastUsedConfig(WorkoutConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUsedConfigKey, jsonEncode(config.toJson()));
  }

  /// Get the last-used workout configuration
  /// Returns null if no configuration has been saved
  static Future<WorkoutConfig?> getLastUsedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_lastUsedConfigKey);

    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return WorkoutConfig.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  // User Preference methods
  /// Enable/disable power user mode (compact layout, auto-load last config)
  static Future<void> setPowerUserMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_powerUserModeKey, enabled);
  }

  /// Check if power user mode is enabled
  /// Defaults to false for first-time users
  static Future<bool> isPowerUserMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_powerUserModeKey) ?? false;
  }
}
