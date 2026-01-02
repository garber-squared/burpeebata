import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';

/// Service for managing workout data in Firestore
/// Workouts are stored in a subcollection under each user: users/{userId}/workouts
class WorkoutService {
  final FirebaseFirestore _firestore;
  static const String _usersCollection = 'users';
  static const String _workoutsSubcollection = 'workouts';

  /// Create WorkoutService with optional Firestore instance (for testing)
  WorkoutService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get reference to user's workouts collection
  CollectionReference _workoutsCollection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_workoutsSubcollection);
  }

  /// Save a workout to Firestore
  Future<void> saveWorkout(String userId, Workout workout) async {
    try {
      await _workoutsCollection(userId).doc(workout.id).set(workout.toJson());
    } catch (e) {
      throw WorkoutServiceException('Failed to save workout: $e');
    }
  }

  /// Get all workouts for a user, sorted by date (newest first)
  Future<List<Workout>> getWorkouts(String userId) async {
    try {
      final querySnapshot = await _workoutsCollection(userId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Workout.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw WorkoutServiceException('Failed to get workouts: $e');
    }
  }

  /// Stream of workouts for a user
  Stream<List<Workout>> workoutsStream(String userId) {
    return _workoutsCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Workout.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get a specific workout by ID
  Future<Workout?> getWorkout(String userId, String workoutId) async {
    try {
      final doc = await _workoutsCollection(userId).doc(workoutId).get();
      if (!doc.exists) {
        return null;
      }
      return Workout.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw WorkoutServiceException('Failed to get workout: $e');
    }
  }

  /// Delete a workout
  Future<void> deleteWorkout(String userId, String workoutId) async {
    try {
      await _workoutsCollection(userId).doc(workoutId).delete();
    } catch (e) {
      throw WorkoutServiceException('Failed to delete workout: $e');
    }
  }

  /// Delete all workouts for a user
  Future<void> deleteAllWorkouts(String userId) async {
    try {
      final querySnapshot = await _workoutsCollection(userId).get();
      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw WorkoutServiceException('Failed to delete all workouts: $e');
    }
  }

  /// Alias for deleteAllWorkouts (matches StorageService interface)
  Future<void> clearAllWorkouts(String userId) async {
    return deleteAllWorkouts(userId);
  }

  /// Get workouts within a date range
  Future<List<Workout>> getWorkoutsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _workoutsCollection(userId)
          .where('date',
              isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Workout.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw WorkoutServiceException('Failed to get workouts in range: $e');
    }
  }

  /// Get recent workouts (limit to n most recent)
  Future<List<Workout>> getRecentWorkouts(String userId, int limit) async {
    try {
      final querySnapshot = await _workoutsCollection(userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Workout.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw WorkoutServiceException('Failed to get recent workouts: $e');
    }
  }

  /// Check if a workout exists
  Future<bool> workoutExists(String userId, String workoutId) async {
    try {
      final doc = await _workoutsCollection(userId).doc(workoutId).get();
      return doc.exists;
    } catch (e) {
      throw WorkoutServiceException('Failed to check if workout exists: $e');
    }
  }
}

/// Custom exception for workout service errors
class WorkoutServiceException implements Exception {
  final String message;

  WorkoutServiceException(this.message);

  @override
  String toString() => message;
}
