import 'package:flutter/material.dart';
import '../services/timer_service.dart';

/// BurpeeBata Design System v2
///
/// This theme system prioritizes:
/// - Training psychology and fatigue-state usability
/// - Numeric dominance and glanceability
/// - Clear semantic separation of color, motion, and sound
/// - Brutally honest performance feedback

/// Color Semantics (Design System v2)
///
/// Each color has a single-purpose, contextual meaning
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

    // Brand & Primary
    static const Color brandPrimary = Color(0xFF6B8E6B); // Desaturated Green

    // Workout Phase Colors
    // Work phase uses gradient from amber to red based on progress
    static const Color workPhaseStart = Color(0xFFFFB74D); // Amber
    static const Color workPhaseEnd = Color(0xFFE53935);   // Red
    static const Color restPhase = Color(0xFF42A5F5);      // Cool Blue
    static const Color countdown = Color(0xFF9E9E9E);      // Neutral Grey

    // Status Colors
    static const Color success = Color(0xFF4CAF50);        // Green
    static const Color warning = Color(0xFFE53935);        // Red
    static const Color critical = Color(0xFFD32F2F);       // Dark Red

    // Workout Parameter Colors (existing system, kept for compatibility)
    static const Color initialCountdown = Colors.blue;
    static const Color numberOfSets = Colors.purple;
    static const Color secondsPerSet = Colors.orange;
    static const Color repsPerSet = Colors.teal;
    static const Color restBetweenSets = Colors.indigo;
}

/// Typography System v2 (Numeric-First)
///
/// Tier 1: Timer countdown (72-88px, Bold, Tabular Figures)
/// Tier 2: Reps, Sets (32-40px, SemiBold)
/// Tier 3: Labels (Material labelMedium)
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

    /// Tier 1: Timer countdown display
    /// Largest, most dominant numeric display
    static TextStyle tier1(BuildContext context, {Color? color}) {
      return TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.bold,
        color: color ?? Colors.white,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -1.5,
      );
    }

    /// Tier 2: Reps and Sets display
    /// Secondary numeric emphasis
    static TextStyle tier2(BuildContext context, {Color? color}) {
      return TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
    }

    /// Tier 3: Labels and descriptions
    /// Non-numeric supporting text
    static TextStyle tier3(BuildContext context, {Color? color}) {
      return Theme.of(context).textTheme.labelMedium!.copyWith(
        color: color,
      );
    }

    /// State label (e.g., "WORK!", "REST")
    /// Medium size, bold, white
    static TextStyle stateLabel(BuildContext context, {Color? color}) {
      return TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color ?? Colors.white,
        letterSpacing: 1.5,
      );
    }
}

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Get work phase background color based on progress
  ///
  /// Creates an amber → red gradient effect as time progresses
  /// - progress: 0.0 (start) → 1.0 (end)
  static Color getWorkPhaseColor(double progress) {
    return Color.lerp(
      AppColors.workPhaseStart,
      AppColors.workPhaseEnd,
      progress,
    )!;
  }

  /// Get background color for timer screen based on state and progress
  ///
  /// Implements Design System v2 color semantics:
  /// - Countdown: Neutral grey
  /// - Work: Amber → Red gradient (based on progress)
  /// - Rest: Cool blue
  /// - Final 3 seconds: Red (critical warning)
  static Color getTimerBackgroundColor({
    required TimerState state,
    required int currentSeconds,
    required double progress,
  }) {
    // Critical warning: last 3 seconds of any active phase
    if ((state == TimerState.work || state == TimerState.rest) &&
        currentSeconds <= 3) {
      return AppColors.critical;
    }

    switch (state) {
      case TimerState.countdown:
        return AppColors.countdown;
      case TimerState.work:
        // Gradient from amber to red based on time progress
        return getWorkPhaseColor(progress);
      case TimerState.rest:
        return AppColors.restPhase;
      case TimerState.finished:
      case TimerState.idle:
        // These will use scaffold background from MaterialApp theme
        return Colors.transparent;
    }
  }

  /// Light theme configuration
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
