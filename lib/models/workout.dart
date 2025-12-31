import 'dart:convert';
import 'burpee_type.dart';

class Workout {
  final String id;
  final DateTime date;
  final BurpeeType burpeeType;
  final int repsPerSet;
  final int secondsPerSet;
  final int numberOfSets;
  final int restBetweenSets;
  final bool completed;
  final int completedSets;
  final bool isCompleted;
  final bool isCompletedInTime;
  final int elapsedSeconds;

  Workout({
    required this.id,
    required this.date,
    required this.burpeeType,
    required this.repsPerSet,
    required this.secondsPerSet,
    required this.numberOfSets,
    required this.restBetweenSets,
    this.completed = false,
    this.completedSets = 0,
    this.isCompleted = false,
    this.isCompletedInTime = false,
    this.elapsedSeconds = 0,
  });

  int get totalReps => repsPerSet * completedSets;

  int get totalWorkoutSeconds => (secondsPerSet * numberOfSets) + (restBetweenSets * (numberOfSets - 1));

  Duration get totalWorkoutDuration => Duration(seconds: totalWorkoutSeconds);

  // Performance Metrics (Design System v2)

  /// Reps per minute - primary intensity metric
  double get repsPerMinute {
    if (elapsedSeconds == 0) return 0.0;
    return (totalReps / elapsedSeconds) * 60;
  }

  /// Work/rest density - percentage of time spent working vs resting
  /// Higher = more intense workout
  double get workRestDensity {
    if (completedSets == 0) return 0.0;
    final totalWorkSeconds = secondsPerSet * completedSets;
    final totalSeconds = elapsedSeconds > 0 ? elapsedSeconds : totalWorkoutSeconds;
    return (totalWorkSeconds / totalSeconds) * 100;
  }

  /// Workout intensity score (0-100) based on completion and pace
  int get intensityScore {
    if (!completed) return (completedSets / numberOfSets * 50).round();

    // Base score from completion
    int score = 70;

    // Bonus for completing all reps
    if (isCompleted) score += 15;

    // Bonus for completing in planned time
    if (isCompletedInTime) score += 15;

    return score.clamp(0, 100);
  }

  Workout copyWith({
    String? id,
    DateTime? date,
    BurpeeType? burpeeType,
    int? repsPerSet,
    int? secondsPerSet,
    int? numberOfSets,
    int? restBetweenSets,
    bool? completed,
    int? completedSets,
    bool? isCompleted,
    bool? isCompletedInTime,
    int? elapsedSeconds,
  }) {
    return Workout(
      id: id ?? this.id,
      date: date ?? this.date,
      burpeeType: burpeeType ?? this.burpeeType,
      repsPerSet: repsPerSet ?? this.repsPerSet,
      secondsPerSet: secondsPerSet ?? this.secondsPerSet,
      numberOfSets: numberOfSets ?? this.numberOfSets,
      restBetweenSets: restBetweenSets ?? this.restBetweenSets,
      completed: completed ?? this.completed,
      completedSets: completedSets ?? this.completedSets,
      isCompleted: isCompleted ?? this.isCompleted,
      isCompletedInTime: isCompletedInTime ?? this.isCompletedInTime,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'burpeeType': burpeeType.index,
      'repsPerSet': repsPerSet,
      'secondsPerSet': secondsPerSet,
      'numberOfSets': numberOfSets,
      'restBetweenSets': restBetweenSets,
      'completed': completed,
      'completedSets': completedSets,
      'isCompleted': isCompleted,
      'isCompletedInTime': isCompletedInTime,
      'elapsedSeconds': elapsedSeconds,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      burpeeType: BurpeeType.values[json['burpeeType'] as int],
      repsPerSet: json['repsPerSet'] as int,
      secondsPerSet: json['secondsPerSet'] as int,
      numberOfSets: json['numberOfSets'] as int,
      restBetweenSets: json['restBetweenSets'] as int,
      completed: json['completed'] as bool,
      completedSets: json['completedSets'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isCompletedInTime: json['isCompletedInTime'] as bool? ?? false,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Workout.fromJsonString(String jsonString) {
    return Workout.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  String get shareText {
    final status = completed ? 'Completed' : 'Attempted';
    final formattedDate = '${date.month}/${date.day}/${date.year}';
    return '''
BurpeeBata Workout - $formattedDate
$status: ${burpeeType.displayName}
Sets: $completedSets/$numberOfSets
Total Reps: $totalReps
''';
  }
}
