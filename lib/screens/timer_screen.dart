import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/workout_config.dart';
import '../models/workout.dart';
import '../models/burpee_type.dart';
import '../services/timer_service.dart';
import '../services/storage_service.dart';
import '../services/workout_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'post_workout_questionnaire_screen.dart';

class TimerScreen extends StatefulWidget {
  final WorkoutConfig config;

  const TimerScreen({super.key, required this.config});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final TimerService _timerService = TimerService();
  final WorkoutService _workoutService = WorkoutService();
  bool _isPaused = false;
  int _lastSeconds = -1;
  TimerState _lastState = TimerState.idle;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _timerService.addListener(_onTimerUpdate);
    _startWorkout();
  }

  Future<void> _startWorkout() async {
    await _timerService.startWorkout(widget.config);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _timerService.removeListener(_onTimerUpdate);
    _timerService.dispose();
    super.dispose();
  }

  void _onTimerUpdate() {
    _handleHapticFeedback();
    setState(() {});
    if (_timerService.state == TimerState.finished) {
      _showPostWorkoutQuestionnaire();
    }
  }

  /// Handle haptic feedback patterns based on workout state
  void _handleHapticFeedback() {
    final currentSeconds = _timerService.currentSeconds;
    final currentState = _timerService.state;

    // Phase transition haptics
    if (_lastState != currentState) {
      if (currentState == TimerState.work) {
        // Work start: single strong tap
        HapticFeedback.heavyImpact();
      } else if (currentState == TimerState.rest) {
        // Rest start: medium tap
        HapticFeedback.mediumImpact();
      }
      _lastState = currentState;
    }

    // Escalating pattern for final seconds (only if seconds changed)
    if (currentSeconds != _lastSeconds &&
        (currentState == TimerState.work || currentState == TimerState.rest)) {
      if (currentSeconds == 3) {
        // 3 seconds: light tap
        HapticFeedback.lightImpact();
      } else if (currentSeconds == 2) {
        // 2 seconds: light tap
        HapticFeedback.lightImpact();
      } else if (currentSeconds == 1) {
        // 1 second: strong tap
        HapticFeedback.heavyImpact();
      } else if (currentSeconds == 0) {
        // Completion: long confirmation pulse (simulated with selection click)
        HapticFeedback.selectionClick();
      }
    }

    _lastSeconds = currentSeconds;
  }

  Future<void> _showPostWorkoutQuestionnaire() async {
    if (!mounted) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PostWorkoutQuestionnaireScreen(
          config: widget.config,
          elapsedSeconds: _timerService.elapsedWorkoutSeconds,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;

    await _saveWorkout(
      completed: true,
      isCompleted: result?['isCompleted'] ?? false,
      isCompletedInTime: result?['isCompletedInTime'] ?? false,
      elapsedSeconds: _timerService.elapsedWorkoutSeconds,
    );
  }

  Future<void> _saveWorkout({
    required bool completed,
    bool isCompleted = false,
    bool isCompletedInTime = false,
    int elapsedSeconds = 0,
  }) async {
    final workout = Workout(
      id: const Uuid().v4(),
      date: DateTime.now(),
      burpeeType: widget.config.burpeeType,
      repsPerSet: widget.config.repsPerSet,
      secondsPerSet: widget.config.secondsPerSet,
      numberOfSets: widget.config.numberOfSets,
      restBetweenSets: widget.config.restBetweenSets,
      completed: completed,
      completedSets: completed ? widget.config.numberOfSets : _timerService.completedSets,
      isCompleted: isCompleted,
      isCompletedInTime: isCompletedInTime,
      elapsedSeconds: elapsedSeconds,
    );

    // Save to local storage
    await StorageService.saveWorkout(workout);

    // Save to Firestore if user is authenticated and not anonymous
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && !authProvider.isAnonymous) {
        try {
          await _workoutService.saveWorkout(authProvider.user!.uid, workout);
        } catch (e) {
          // Log error but don't fail the save - local storage already succeeded
          debugPrint('Failed to save workout to Firestore: $e');
        }
      }
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timerService.pause();
      } else {
        _timerService.resume();
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (_timerService.state == TimerState.finished) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Workout?'),
        content: const Text('Are you sure you want to end this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await _saveWorkout(completed: false);
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('END WORKOUT'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _getBackgroundColor(),
        body: SafeArea(
          child: _timerService.state == TimerState.finished
              ? _buildFinishedView()
              : _buildTimerView(),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    // Use Design System v2 color semantics
    final bgColor = AppTheme.getTimerBackgroundColor(
      state: _timerService.state,
      currentSeconds: _timerService.currentSeconds,
      progress: _timerService.progress,
    );

    // Return theme colors for finished/idle states
    if (_timerService.state == TimerState.finished) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    if (_timerService.state == TimerState.idle) {
      return Theme.of(context).scaffoldBackgroundColor;
    }

    return bgColor;
  }

  Widget _buildTimerView() {
    // Calculate if we're in final seconds for opacity fading
    final isFinalSeconds = _timerService.currentSeconds <= 3 &&
        (_timerService.state == TimerState.work ||
            _timerService.state == TimerState.rest);

    // Calculate if we're in final 5 seconds for pulse animation
    final isFinal5Seconds = _timerService.currentSeconds <= 5 &&
        (_timerService.state == TimerState.work ||
            _timerService.state == TimerState.rest);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Set count - appears above timer
                AnimatedOpacity(
                  opacity: isFinalSeconds ? 0.4 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    'Set ${_timerService.currentSet} / ${_timerService.totalSets}',
                    style: AppTypography.tier2(context),
                  ),
                ),
                const SizedBox(height: 40),

                // Timer - dominant central element
                // Progress ring now wraps around the timer
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress ring animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween<double>(
                        begin: _getProgressRingValue(),
                        end: _getProgressRingValue(),
                      ),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: isFinal5Seconds ? 1.02 : 1.0,
                          child: SizedBox(
                            width: 240,
                            height: 240,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 14,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                    // State label
                    Positioned(
                      top: 50,
                      child: AnimatedOpacity(
                        opacity: isFinalSeconds ? 0.4 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _getStateLabel(),
                          style: AppTypography.tier3(context).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Timer number - absolute focus
                    AnimatedScale(
                      scale: isFinalSeconds ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        '${_timerService.currentSeconds}',
                        style: AppTypography.tier1(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Reps/percentage info - below timer
                AnimatedOpacity(
                  opacity: isFinalSeconds ? 0.4 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildInfoText(),
                ),
              ],
            ),
          ),
        ),

        // Controls - fatigue-safe positioning
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pause button - large, single tap
              FloatingActionButton.large(
                heroTag: 'pause',
                onPressed: _togglePause,
                backgroundColor: Colors.white,
                child: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: _getBackgroundColor(),
                  size: 40,
                ),
              ),
              // Stop button - smaller, requires long press
              FloatingActionButton(
                heroTag: 'stop',
                onPressed: null, // Disabled for tap
                backgroundColor: Colors.white70,
                child: GestureDetector(
                  onLongPress: () async {
                    if (await _onWillPop()) {
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Icon(
                    Icons.stop,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get progress ring value based on workout phase
  /// - Work phase: ring SHRINKS (1.0 → 0.0) as time is consumed
  /// - Rest phase: ring FILLS (0.0 → 1.0) as recovery accumulates
  double _getProgressRingValue() {
    if (_timerService.state == TimerState.work) {
      // Work: show remaining time (shrinks from full to empty)
      return _timerService.progress;
    } else if (_timerService.state == TimerState.rest) {
      // Rest: show accumulating rest (fills from empty to full)
      return _timerService.progress;
    } else if (_timerService.state == TimerState.countdown) {
      // Countdown: shrinks like work phase
      return _timerService.progress;
    }
    return 0.0;
  }

  /// Build info text based on current state
  Widget _buildInfoText() {
    if (_timerService.state == TimerState.work) {
      return Text(
        'Rep ${_timerService.currentRep} / ${_timerService.repsPerSet}',
        style: AppTypography.tier2(context),
      );
    } else if (_timerService.state == TimerState.rest) {
      return Text(
        '${_calculateCompletedPercentage()}% complete',
        style: AppTypography.tier2(context, color: Colors.white70),
      );
    } else {
      return Text(
        '${widget.config.repsPerSet} reps per set',
        style: AppTypography.tier2(context, color: Colors.white70),
      );
    }
  }

  String _getStateLabel() {
    switch (_timerService.state) {
      case TimerState.countdown:
        return 'GET READY!';
      case TimerState.work:
        return 'WORK!';
      case TimerState.rest:
        return 'REST';
      default:
        return '';
    }
  }

  int _calculateCompletedPercentage() {
    final totalReps = widget.config.repsPerSet * widget.config.numberOfSets;
    // During rest, currentSet shows the upcoming set, so completed sets = currentSet - 1
    final completedSets = _timerService.currentSet - 1;
    final completedReps = completedSets * widget.config.repsPerSet;
    return ((completedReps / totalReps) * 100).round();
  }

  Widget _buildFinishedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'WORKOUT COMPLETE!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.config.numberOfSets} sets × ${widget.config.repsPerSet} reps',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${widget.config.numberOfSets * widget.config.repsPerSet} total ${widget.config.burpeeType.displayName}s',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }
}
