import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/workout_config.dart';

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

  static const int _countdownSeconds = 3;

  TimerState get state => _state;
  int get currentSeconds => _currentSeconds;
  int get currentSet => _currentSet;
  int get totalSets => _totalSets;
  int get workSeconds => _workSeconds;
  int get restSeconds => _restSeconds;

  bool get isRunning => _state != TimerState.idle && _state != TimerState.finished;

  double get progress {
    if (_state == TimerState.idle || _state == TimerState.finished) return 0;
    if (_state == TimerState.countdown) {
      return 1 - (_currentSeconds / _countdownSeconds);
    }
    if (_state == TimerState.work) {
      return 1 - (_currentSeconds / _workSeconds);
    }
    if (_state == TimerState.rest) {
      return 1 - (_currentSeconds / _restSeconds);
    }
    return 0;
  }

  void startWorkout(WorkoutConfig config) {
    _totalSets = config.numberOfSets;
    _workSeconds = config.secondsPerSet;
    _restSeconds = config.restBetweenSets;
    _currentSet = 1;

    _startCountdown();
  }

  void _startCountdown() {
    _state = TimerState.countdown;
    _currentSeconds = _countdownSeconds;
    notifyListeners();
    _startTimer();
  }

  void _startWork() {
    _state = TimerState.work;
    _currentSeconds = _workSeconds;
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
        if (_currentSet < _totalSets) {
          _currentSet++;
          _startRest();
        } else {
          _finish();
        }
        break;
      case TimerState.rest:
        _startCountdown();
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
