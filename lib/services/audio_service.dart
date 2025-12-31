import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _beepPlayer = AudioPlayer();
  final AudioPlayer _whistlePlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _pingPlayer = AudioPlayer();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Configure players for low latency
    await _beepPlayer.setReleaseMode(ReleaseMode.stop);
    await _whistlePlayer.setReleaseMode(ReleaseMode.stop);
    await _bellPlayer.setReleaseMode(ReleaseMode.stop);
    await _pingPlayer.setReleaseMode(ReleaseMode.stop);

    _isInitialized = true;
  }

  /// Play countdown beep with escalating pitch
  /// Design System v2: Rising pitch creates urgency
  Future<void> playCountdownBeep({int secondsRemaining = 3}) async {
    await _beepPlayer.stop();

    // Escalate pitch based on urgency (3s = 1.0x, 2s = 1.1x, 1s = 1.2x)
    final playbackRate = switch (secondsRemaining) {
      3 => 1.0,
      2 => 1.1,
      1 => 1.2,
      _ => 1.0,
    };

    await _beepPlayer.setPlaybackRate(playbackRate);
    await _beepPlayer.play(AssetSource('audio/countdown_beep.mp3'));
  }

  /// Work start: Sharp, high-urgency signal
  /// Design System v2: Sharp attack, no tail
  Future<void> playWorkStart() async {
    await _whistlePlayer.stop();
    await _whistlePlayer.setPlaybackRate(1.0);
    await _whistlePlayer.play(AssetSource('audio/whistle.mp3'));
  }

  /// Rest start: Lower, softer signal
  /// Design System v2: Lower pitch, less urgent than work
  Future<void> playRestStart() async {
    await _pingPlayer.stop();
    // Lower pitch for rest (90% speed = lower tone)
    await _pingPlayer.setPlaybackRate(0.9);
    await _pingPlayer.setVolume(0.7); // Softer volume
    await _pingPlayer.play(AssetSource('audio/ping.mp3'));
  }

  /// Set/phase completion: Boxing bell
  Future<void> playPhaseComplete() async {
    await _bellPlayer.stop();
    await _bellPlayer.setPlaybackRate(1.0);
    await _bellPlayer.play(AssetSource('audio/boxing_bell.mp3'));
  }

  /// Rep tick: Subtle progress indicator
  Future<void> playRepTick() async {
    await _pingPlayer.stop();
    await _pingPlayer.setPlaybackRate(1.0);
    await _pingPlayer.setVolume(0.5); // Quieter for non-critical feedback
    await _pingPlayer.play(AssetSource('audio/ping.mp3'));
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
    _isInitialized = false;
  }
}
