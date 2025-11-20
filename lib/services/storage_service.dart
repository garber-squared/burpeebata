import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';

class StorageService {
  static const String _workoutsKey = 'workouts';

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
}
