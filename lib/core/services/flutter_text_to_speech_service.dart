import 'package:flutter_tts/flutter_tts.dart';

import 'text_to_speech_service.dart';

class FlutterTextToSpeechService implements TextToSpeechService {
  FlutterTextToSpeechService(this._tts);

  final FlutterTts _tts;

  @override
  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  @override
  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
