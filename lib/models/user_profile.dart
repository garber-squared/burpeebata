/// Represents a user's optional profile information.
/// All fields except userId are optional to allow gradual profile completion.
class UserProfile {
  final String userId;
  final String? name;
  final int? age;
  final Sex sex;
  final double? heightCm;
  final double? weightKg;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.userId,
    this.name,
    this.age,
    this.sex = Sex.male,
    this.heightCm,
    this.weightKg,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a new empty profile for a user
  factory UserProfile.empty(String userId) {
    return UserProfile(
      userId: userId,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a UserProfile from a JSON map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      name: json['name'] as String?,
      age: json['age'] as int?,
      sex: json['sex'] != null
          ? Sex.fromString(json['sex'] as String)
          : Sex.male,
      heightCm: json['heightCm'] as double?,
      weightKg: json['weightKg'] as double?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Converts this UserProfile to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'age': age,
      'sex': sex.value,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Creates a copy of this UserProfile with updated fields
  UserProfile copyWith({
    String? name,
    int? age,
    Sex? sex,
    double? heightCm,
    double? weightKg,
  }) {
    return UserProfile(
      userId: userId,
      name: name ?? this.name,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns true if any profile fields have been filled in
  bool get isComplete {
    return name != null ||
        age != null ||
        heightCm != null ||
        weightKg != null;
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, name: $name, age: $age, sex: $sex, heightCm: $heightCm, weightKg: $weightKg)';
  }
}

/// Enum for biological sex - defaults to male
enum Sex {
  male('male'),
  female('female');

  final String value;

  const Sex(this.value);

  static Sex fromString(String value) {
    switch (value.toLowerCase()) {
      case 'female':
        return Sex.female;
      case 'male':
      default:
        return Sex.male;
    }
  }

  String get displayName {
    switch (this) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
    }
  }
}
