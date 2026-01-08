import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _beepPlayer = AudioPlayer();
  final AudioPlayer _whistlePlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _pingPlayer = AudioPlayer();
  final AudioPlayer _victoryPlayer = AudioPlayer();
  final AudioPlayer _endOfRestPlayer = AudioPlayer();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Configure players for low latency
    await _beepPlayer.setReleaseMode(ReleaseMode.stop);
    await _whistlePlayer.setReleaseMode(ReleaseMode.stop);
    await _bellPlayer.setReleaseMode(ReleaseMode.stop);
    await _pingPlayer.setReleaseMode(ReleaseMode.stop);
    await _victoryPlayer.setReleaseMode(ReleaseMode.stop);
    await _endOfRestPlayer.setReleaseMode(ReleaseMode.stop);

    _isInitialized = true;
  }

  /// Play countdown beep with escalating pitch
  /// Design System v2: Rising pitch creates urgency
  /// Uses last_rep_pulse.wav for final second, rep_pulse.wav for earlier seconds
  Future<void> playCountdownBeep({int secondsRemaining = 3}) async {
    await _beepPlayer.stop();

    // Use distinct sound for last second, regular pulse for earlier seconds
    final audioFile = secondsRemaining == 1
        ? 'audio/last_rep_pulse.wav'
        : 'audio/rep_pulse.wav';

    // Slight pitch escalation for urgency
    final playbackRate = switch (secondsRemaining) {
      3 => 1.0,
      2 => 1.05,
      1 => 1.1,
      _ => 1.0,
    };

    await _beepPlayer.setPlaybackRate(playbackRate);
    await _beepPlayer.play(AssetSource(audioFile));
  }

  /// Work start: Sharp, high-urgency signal
  /// Design System v2: Sharp attack, no tail
  Future<void> playWorkStart() async {
    await _whistlePlayer.stop();
    await _whistlePlayer.setPlaybackRate(1.0);
    await _whistlePlayer.play(AssetSource('audio/start_set_whistle.wav'));
  }

  /// Rest start: Lower, softer signal
  /// Design System v2: Lower pitch, less urgent than work
  Future<void> playRestStart() async {
    await _pingPlayer.stop();
    // Lower pitch for rest (90% speed = lower tone)
    await _pingPlayer.setPlaybackRate(0.9);
    await _pingPlayer.setVolume(0.7); // Softer volume
    await _pingPlayer.play(AssetSource('audio/rep_pulse.wav'));
  }

  /// Set/phase completion: End of set sound
  Future<void> playPhaseComplete() async {
    await _bellPlayer.stop();
    await _bellPlayer.setPlaybackRate(1.0);
    await _bellPlayer.play(AssetSource('audio/end_of_set.wav'));
  }

  /// Rep tick: Subtle progress indicator
  Future<void> playRepTick() async {
    await _pingPlayer.stop();
    await _pingPlayer.setPlaybackRate(1.0);
    await _pingPlayer.setVolume(0.5); // Quieter for non-critical feedback
    await _pingPlayer.play(AssetSource('audio/rep_pulse.wav'));
  }

  /// Victory fanfare: Celebratory sound for workout completion
  Future<void> playVictory() async {
    await _victoryPlayer.stop();
    await _victoryPlayer.setPlaybackRate(1.0);
    await _victoryPlayer.setVolume(1.0); // Full volume for celebration
    await _victoryPlayer.play(AssetSource('audio/end_of_workout.wav'));
  }

  /// End of rest warning: Plays during last 3 seconds (or less) of rest period
  /// If rest >= 3 seconds: plays full audio
  /// If rest < 3 seconds: plays from appropriate starting point
  Future<void> playEndOfRest({required int restDuration}) async {
    await _endOfRestPlayer.stop();
    await _endOfRestPlayer.setPlaybackRate(1.0);
    await _endOfRestPlayer.setVolume(1.0);

    // For rest periods < 3 seconds, adjust playback speed to fit duration
    // This allows the sound to compress naturally into shorter rest periods
    if (restDuration < 3) {
      final speedMultiplier = 3.0 / restDuration;
      await _endOfRestPlayer.setPlaybackRate(speedMultiplier);
    }

    await _endOfRestPlayer.play(AssetSource('audio/end_of_rest.wav'));
  }

  /// Legacy methods for backward compatibility
  @Deprecated('Use playWorkStart() instead')
  Future<void> playWhistle() async => playWorkStart();

  @Deprecated('Use playPhaseComplete() instead')
  Future<void> playBell() async => playPhaseComplete();

  @Deprecated('Use playRepTick() instead')
  Future<void> playPing() async => playRepTick();

  void dispose() {
    _beepPlayer.dispose();
    _whistlePlayer.dispose();
    _bellPlayer.dispose();
    _pingPlayer.dispose();
    _victoryPlayer.dispose();
    _endOfRestPlayer.dispose();
    _isInitialized = false;
  }
}
