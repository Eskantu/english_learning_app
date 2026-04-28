import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import 'speech_to_text_service.dart';

class FlutterSpeechToTextService implements SpeechToTextService {
  FlutterSpeechToTextService(this._speech);

  final SpeechToText _speech;
  @override
  Future<void> initialize() async {
    await _speech.initialize();
  }

  @override
  Future<String?> listenOnce() async {
    final bool available = await _speech.initialize();
    print('Speech recognition available: $available');
    if (!available) {
      return null;
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

    Timer(const Duration(seconds: 9), () async {
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
    await _speech.stop();
  }
}
