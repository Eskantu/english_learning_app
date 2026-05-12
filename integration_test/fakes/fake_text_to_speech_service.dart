import 'package:english_learning_ap/core/services/text_to_speech_service.dart';

class FakeTextToSpeechService implements TextToSpeechService {
  final List<String> spokenTexts = <String>[];
  Object? speakError;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initializeIfNeeded() async {
    _initialized = true;
  }

  @override
  Future<void> speak(String text) async {
    await initializeIfNeeded();
    spokenTexts.add(text);
    if (speakError != null) {
      throw speakError!;
    }
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    _initialized = false;
  }

  void reset() {
    spokenTexts.clear();
    speakError = null;
    _initialized = false;
  }
}
