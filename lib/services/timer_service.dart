import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/workout_config.dart';
import 'audio_service.dart';

enum TimerState {
  idle,
  countdown,
  work,
  rest,
  finished,
}

class TimerService extends ChangeNotifier {
  Timer? _timer;
  TimerState _state = TimerState.idle;
  int _currentCentiseconds = 0;  // Track time in centiseconds (1/100th of a second)
  int _currentSet = 0;
  int _totalSets = 0;
  int _workSeconds = 0;
  int _restSeconds = 0;
  int _repsPerSet = 0;
  int _lastRep = 0;
  int _initialCountdownSeconds = 10;
  int _elapsedWorkoutSeconds = 0;
  bool _workoutStarted = false;
  bool _endOfRestPlayed = false;
  final AudioService _audioService;

  TimerService({AudioService? audioService})
      : _audioService = audioService ?? AudioService();

  TimerState get state => _state;
  double get currentSeconds => _currentCentiseconds / 100.0;
  int get currentSet => _currentSet;
  int get totalSets => _totalSets;
  int get workSeconds => _workSeconds;
  int get restSeconds => _restSeconds;
  int get repsPerSet => _repsPerSet;
  int get elapsedWorkoutSeconds => _elapsedWorkoutSeconds;

  int get currentRep {
    if (_state != TimerState.work || _repsPerSet <= 0) {
      return 0;
    }

    final elapsedSeconds = _workSeconds - currentSeconds;
    final secondsPerRep = _workSeconds / _repsPerSet;

    if (secondsPerRep <= 0) {
      return 1;
    }

    final rep = (elapsedSeconds / secondsPerRep).floor() + 1;
    return rep.clamp(1, _repsPerSet);
  }

  bool get isRunning => _state != TimerState.idle && _state != TimerState.finished;

  double get progress {
    if (_state == TimerState.idle || _state == TimerState.finished) return 0;
    if (_state == TimerState.countdown) {
      return 1 - (currentSeconds / _initialCountdownSeconds);
    }
    if (_state == TimerState.work) {
      return 1 - (currentSeconds / _workSeconds);
    }
    if (_state == TimerState.rest) {
      return 1 - (currentSeconds / _restSeconds);
    }
    return 0;
  }

  Future<void> startWorkout(WorkoutConfig config) async {
    await _audioService.init();

    _totalSets = config.numberOfSets;
    _workSeconds = config.secondsPerSet;
    _restSeconds = config.restBetweenSets;
    _repsPerSet = config.repsPerSet;
    _initialCountdownSeconds = config.initialCountdown;
    _currentSet = 1;

    _startCountdown();
  }

  void _startCountdown() {
    _state = TimerState.countdown;
    _currentCentiseconds = _initialCountdownSeconds * 100;
    notifyListeners();
    _startTimer();
  }

  void _startWork() {
    _state = TimerState.work;
    _currentCentiseconds = _workSeconds * 100;
    _lastRep = 1; // Reset to first rep
    // Mark workout as started on first work set (excludes countdown from elapsed time)
    if (!_workoutStarted) {
      _workoutStarted = true;
    }
    // Play sharp work start signal (Design System v2)
    _audioService.playWorkStart();
    notifyListeners();
    _startTimer();
  }

  void _startRest() {
    _state = TimerState.rest;
    _currentCentiseconds = _restSeconds * 100;
    _endOfRestPlayed = false; // Reset flag for new rest period
    // Play softer rest start signal (Design System v2)
    _audioService.playRestStart();
    notifyListeners();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      _tick();
    });
  }

  void _tick() {
    if (_currentCentiseconds <= 0) {
      // Timer reached 0 - transition states
      _timer?.cancel();

    switch (_state) {
      case TimerState.countdown:
        _startWork();
        break;
      case TimerState.work:
        // Play phase completion sound (Design System v2)
        _audioService.playPhaseComplete();
        if (_currentSet < _totalSets) {
          _currentSet++;
          _startRest();
        } else {
          _finish();
        }
        break;
      case TimerState.rest:
        // Go directly to work - countdown was integrated into last 3 seconds of rest
        _startWork();
        break;
      case TimerState.idle:
      case TimerState.finished:
        break;
    }
      return;
    }

    // Decrement timer
    _currentCentiseconds--;

    // Track elapsed time only after workout has started (excludes countdown)
    // Increment elapsed seconds every 100 centiseconds (1 second)
    if (_workoutStarted && _currentCentiseconds % 100 == 99) {
      _elapsedWorkoutSeconds++;
    }

    // Get current seconds for audio cue checks
    final secondsRemaining = currentSeconds.ceil();

    // Play escalating countdown beep in last 3 seconds (Design System v2)
    // Only trigger once per second (when we cross the whole second boundary)
    if (_currentCentiseconds % 100 == 99) {
      if (_state == TimerState.countdown && secondsRemaining <= 3 && secondsRemaining > 0) {
        _audioService.playCountdownBeep(secondsRemaining: secondsRemaining);
      }
      // Play escalating countdown beep in last 3 seconds of work period
      if (_state == TimerState.work && secondsRemaining <= 3 && secondsRemaining > 0) {
        _audioService.playCountdownBeep(secondsRemaining: secondsRemaining);
      }
      // Play end of rest sound during rest period
      if (_state == TimerState.rest && !_endOfRestPlayed) {
        // For rest >= 3 seconds: play when 3 seconds remain
        // For rest < 3 seconds: play immediately (at start of rest)
        final triggerTime = _restSeconds >= 3 ? 3 : _restSeconds;
        if (secondsRemaining <= triggerTime && secondsRemaining > 0) {
          _audioService.playEndOfRest(restDuration: _restSeconds);
          _endOfRestPlayed = true;
        }
      }
    }

    // Play rep tick sound when rep changes (Design System v2)
    if (_state == TimerState.work && _repsPerSet > 1) {
      final newRep = currentRep;
      if (newRep > _lastRep) {
        _audioService.playRepTick();
        _lastRep = newRep;
      }
    }

    notifyListeners();
  }

  void _finish() {
    _state = TimerState.finished;
    _currentCentiseconds = 0;
    // Play victorious sound for workout completion
    _audioService.playVictory();
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
  }

  void resume() {
    if (isRunning) {
      _startTimer();
    }
  }

  void stop() {
    _timer?.cancel();
    _state = TimerState.idle;
    _currentCentiseconds = 0;
    _currentSet = 0;
    _elapsedWorkoutSeconds = 0;
    _workoutStarted = false;
    _endOfRestPlayed = false;
    notifyListeners();
  }

  int get completedSets {
    if (_state == TimerState.finished) {
      return _totalSets;
    }
    if (_state == TimerState.work || _state == TimerState.countdown) {
      return _currentSet - 1;
    }
    return _currentSet;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
