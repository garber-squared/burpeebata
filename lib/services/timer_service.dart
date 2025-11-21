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
  int _currentSeconds = 0;
  int _currentSet = 0;
  int _totalSets = 0;
  int _workSeconds = 0;
  int _restSeconds = 0;
  int _repsPerSet = 0;
  int _lastRep = 0;
  int _initialCountdownSeconds = 10;
  final AudioService _audioService;

  TimerService({AudioService? audioService})
      : _audioService = audioService ?? AudioService();

  TimerState get state => _state;
  int get currentSeconds => _currentSeconds;
  int get currentSet => _currentSet;
  int get totalSets => _totalSets;
  int get workSeconds => _workSeconds;
  int get restSeconds => _restSeconds;
  int get repsPerSet => _repsPerSet;

  int get currentRep {
    if (_state != TimerState.work || _repsPerSet <= 0) {
      return 0;
    }

    final elapsedSeconds = _workSeconds - _currentSeconds;
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
      return 1 - (_currentSeconds / _initialCountdownSeconds);
    }
    if (_state == TimerState.work) {
      return 1 - (_currentSeconds / _workSeconds);
    }
    if (_state == TimerState.rest) {
      return 1 - (_currentSeconds / _restSeconds);
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
    _currentSeconds = _initialCountdownSeconds;
    notifyListeners();
    _startTimer();
  }

  void _startWork() {
    _state = TimerState.work;
    _currentSeconds = _workSeconds;
    _lastRep = 1; // Reset to first rep
    // Play whistle to signal start of work
    _audioService.playWhistle();
    notifyListeners();
    _startTimer();
  }

  void _startRest() {
    _state = TimerState.rest;
    _currentSeconds = _restSeconds;
    notifyListeners();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    if (_currentSeconds > 1) {
      _currentSeconds--;
      // Play countdown beep in last 3 seconds of initial countdown
      if (_state == TimerState.countdown && _currentSeconds <= 3) {
        _audioService.playCountdownBeep();
      }
      // Play countdown beep in last 3 seconds of work period
      if (_state == TimerState.work && _currentSeconds <= 3) {
        _audioService.playCountdownBeep();
      }
      // Play ping sound when rep changes (after first rep)
      if (_state == TimerState.work && _repsPerSet > 1) {
        final newRep = currentRep;
        if (newRep > _lastRep) {
          _audioService.playPing();
          _lastRep = newRep;
        }
      }
      // Play countdown beep in last 3 seconds of rest period
      if (_state == TimerState.rest && _currentSeconds <= 3) {
        _audioService.playCountdownBeep();
      }
      notifyListeners();
      return;
    }

    // Timer reached 0
    _timer?.cancel();

    switch (_state) {
      case TimerState.countdown:
        _startWork();
        break;
      case TimerState.work:
        // Play bell when work ends
        _audioService.playBell();
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
  }

  void _finish() {
    _state = TimerState.finished;
    _currentSeconds = 0;
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
    _currentSeconds = 0;
    _currentSet = 0;
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
