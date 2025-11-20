enum BurpeeType {
  militarySixCount,
  navySeal,
}

extension BurpeeTypeExtension on BurpeeType {
  String get displayName {
    switch (this) {
      case BurpeeType.militarySixCount:
        return '6-Count Military Burpee';
      case BurpeeType.navySeal:
        return 'Navy Seal Burpee';
    }
  }

  String get description {
    switch (this) {
      case BurpeeType.militarySixCount:
        return 'A six-part compound movement. Emphasizes leg and posterior chain work. Excels at building leg strength and cardiovascular fitness.';
      case BurpeeType.navySeal:
        return '10 component parts. Upper body dominates counts 3-8. Superior for building upper body strength and muscle mass.';
    }
  }

  int get componentCount {
    switch (this) {
      case BurpeeType.militarySixCount:
        return 6;
      case BurpeeType.navySeal:
        return 10;
    }
  }
}
