import 'package:flutter_tts/flutter_tts.dart';

import 'text_to_speech_service.dart';

class FlutterTextToSpeechService implements TextToSpeechService {
  FlutterTextToSpeechService(this._tts);

  final FlutterTts _tts;
  bool _initialized = false;
  Future<void>? _initializing;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initializeIfNeeded() async {
    if (_initialized) {
      return;
    }
    if (_initializing != null) {
      await _initializing;
      return;
    }

    _initializing = _doInitialize();
    await _initializing;
    _initializing = null;
  }

  Future<void> _doInitialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  @override
  Future<void> speak(String text) async {
    await initializeIfNeeded();
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    if (!_initialized) {
      return;
    }
    await _tts.stop();
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }
    await _tts.stop();
    _initialized = false;
  }
}
