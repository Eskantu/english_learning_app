import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import 'speech_to_text_service.dart';

class FlutterSpeechToTextService implements SpeechToTextService {
  FlutterSpeechToTextService(this._speech);

  final SpeechToText _speech;
  bool _initialized = false;
  bool _available = false;
  Future<void>? _initializing;
  Timer? _listenTimeout;

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
    _available = await _speech.initialize();
    _initialized = true;
    print('Speech recognition initialized: $_available');
  }

  @override
  Future<String?> listenOnce() async {
    await initializeIfNeeded();
    if (!_available) {
      print('Speech recognition not available');
      return null;
    }

    if (_speech.isListening) {
      await _speech.stop();
    }

    final Completer<String?> completer = Completer<String?>();
    String? recognizedWords;

    await _speech.listen(
      localeId: 'en_US',
      listenMode: ListenMode.confirmation,
      partialResults: false,
      onResult: (result) {
        recognizedWords = result.recognizedWords.trim();
      },
      onSoundLevelChange: (_) {},
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
    );

    _listenTimeout?.cancel();
    _listenTimeout = Timer(const Duration(seconds: 9), () async {
      await _speech.stop();
      if (!completer.isCompleted) {
        completer.complete(
          recognizedWords == null || recognizedWords!.isEmpty
              ? null
              : recognizedWords,
        );
      }
    });

    return completer.future;
  }

  @override
  Future<void> stop() async {
    _listenTimeout?.cancel();
    _listenTimeout = null;
    await _speech.stop();
  }

  @override
  Future<void> dispose() async {
    _listenTimeout?.cancel();
    _listenTimeout = null;
    await _speech.stop();
    _initialized = false;
    _available = false;
  }
}
