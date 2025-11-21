import 'burpee_type.dart';

class WorkoutConfig {
  final BurpeeType burpeeType;
  final int repsPerSet;
  final int secondsPerSet;
  final int numberOfSets;
  final int restBetweenSets;

  const WorkoutConfig({
    this.burpeeType = BurpeeType.militarySixCount,
    this.repsPerSet = 5,
    this.secondsPerSet = 20,
    this.numberOfSets = 10,
    this.restBetweenSets = 4,
  });

  factory WorkoutConfig.forBurpeeType(BurpeeType type) {
    switch (type) {
      case BurpeeType.militarySixCount:
        return const WorkoutConfig(
          burpeeType: BurpeeType.militarySixCount,
          repsPerSet: 5,
          secondsPerSet: 20,
          numberOfSets: 10,
          restBetweenSets: 4,
        );
      case BurpeeType.navySeal:
        return const WorkoutConfig(
          burpeeType: BurpeeType.navySeal,
          repsPerSet: 2,
          secondsPerSet: 15,
          numberOfSets: 10,
          restBetweenSets: 13,
        );
    }
  }

  WorkoutConfig copyWith({
    BurpeeType? burpeeType,
    int? repsPerSet,
    int? secondsPerSet,
    int? numberOfSets,
    int? restBetweenSets,
  }) {
    return WorkoutConfig(
      burpeeType: burpeeType ?? this.burpeeType,
      repsPerSet: repsPerSet ?? this.repsPerSet,
      secondsPerSet: secondsPerSet ?? this.secondsPerSet,
      numberOfSets: numberOfSets ?? this.numberOfSets,
      restBetweenSets: restBetweenSets ?? this.restBetweenSets,
    );
  }

  int get totalWorkoutSeconds =>
      (secondsPerSet * numberOfSets) + (restBetweenSets * (numberOfSets - 1));

  Duration get totalWorkoutDuration => Duration(seconds: totalWorkoutSeconds);

  String get formattedDuration {
    final duration = totalWorkoutDuration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
