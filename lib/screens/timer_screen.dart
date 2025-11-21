import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import '../models/workout_config.dart';
import '../models/workout.dart';
import '../models/burpee_type.dart';
import '../services/timer_service.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

class TimerScreen extends StatefulWidget {
  final WorkoutConfig config;

  const TimerScreen({super.key, required this.config});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final TimerService _timerService = TimerService();
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
    _timerService.addListener(_onTimerUpdate);
    _startWorkout();
  }

  Future<void> _startWorkout() async {
    await _timerService.startWorkout(widget.config);
  }

  @override
  void dispose() {
    Wakelock.disable();
    _timerService.removeListener(_onTimerUpdate);
    _timerService.dispose();
    super.dispose();
  }

  void _onTimerUpdate() {
    setState(() {});
    if (_timerService.state == TimerState.finished) {
      _saveWorkout(completed: true);
    }
  }

  Future<void> _saveWorkout({required bool completed}) async {
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
    );

    await StorageService.saveWorkout(workout);
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
    return WillPopScope(
      onWillPop: _onWillPop,
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
    // Show red during countdown periods (last 3 seconds of work or rest)
    if (_timerService.state == TimerState.work && _timerService.currentSeconds <= 3) {
      return Colors.red;
    }
    if (_timerService.state == TimerState.rest && _timerService.currentSeconds <= 3) {
      return Colors.red;
    }

    switch (_timerService.state) {
      case TimerState.countdown:
        return Colors.orange;
      case TimerState.work:
        return Colors.green;
      case TimerState.rest:
        return Colors.blue;
      case TimerState.finished:
        return Theme.of(context).colorScheme.primaryContainer;
      case TimerState.idle:
        return Theme.of(context).scaffoldBackgroundColor;
    }
  }

  Widget _buildTimerView() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getStateLabel(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _timerService.progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Text(
                      '${_timerService.currentSeconds}',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_timerService.state == TimerState.work)
                  Text(
                    'Rep ${_timerService.currentRep}/${_timerService.repsPerSet}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                else if (_timerService.state == TimerState.rest)
                  Text(
                    '${_calculateCompletedPercentage()}% done',
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white70,
                    ),
                  )
                else
                  Text(
                    '${widget.config.repsPerSet} reps',
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(height: 32),
                Text(
                  'Set ${_timerService.currentSet} of ${_timerService.totalSets}',
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                onPressed: _togglePause,
                backgroundColor: Colors.white,
                child: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: _getBackgroundColor(),
                  size: 32,
                ),
              ),
              FloatingActionButton(
                onPressed: () async {
                  if (await _onWillPop()) {
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.stop,
                  color: Colors.red,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
