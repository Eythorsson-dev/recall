import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  double _playbackSpeed = 1.0;
  int _replayCount = 0;

  double get playbackSpeed => _playbackSpeed;
  int get replayCount => _replayCount;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_playbackSpeed);
  }

  Future<void> speak(String text) async {
    await _tts.setSpeechRate(_playbackSpeed);
    await _tts.speak(text);
  }

  Future<void> replay(String text) async {
    _replayCount++;
    await speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.5, 2.0);
    await _tts.setSpeechRate(_playbackSpeed);
  }

  void resetReplayCount() {
    _replayCount = 0;
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
