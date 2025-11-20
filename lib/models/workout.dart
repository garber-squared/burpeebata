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
  });

  int get totalReps => repsPerSet * completedSets;

  int get totalWorkoutSeconds => (secondsPerSet * numberOfSets) + (restBetweenSets * (numberOfSets - 1));

  Duration get totalWorkoutDuration => Duration(seconds: totalWorkoutSeconds);

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
Burbata Workout - $formattedDate
$status: ${burpeeType.displayName}
Sets: $completedSets/$numberOfSets
Total Reps: $totalReps
''';
  }
}
