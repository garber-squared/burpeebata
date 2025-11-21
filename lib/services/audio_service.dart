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

  Future<void> playCountdownBeep() async {
    await _beepPlayer.stop();
    await _beepPlayer.play(AssetSource('audio/countdown_beep.mp3'));
  }

  Future<void> playWhistle() async {
    await _whistlePlayer.stop();
    await _whistlePlayer.play(AssetSource('audio/whistle.mp3'));
  }

  Future<void> playBell() async {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('audio/boxing_bell.mp3'));
  }

  Future<void> playPing() async {
    await _pingPlayer.stop();
    await _pingPlayer.play(AssetSource('audio/ping.mp3'));
  }

  void dispose() {
    _beepPlayer.dispose();
    _whistlePlayer.dispose();
    _bellPlayer.dispose();
    _pingPlayer.dispose();
    _isInitialized = false;
  }
}
