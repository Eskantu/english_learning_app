import 'package:english_learning_ap/core/services/text_to_speech_service.dart';

class FakeTextToSpeechService implements TextToSpeechService {
  final List<String> spokenTexts = <String>[];
  Object? speakError;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text) async {
    spokenTexts.add(text);
    if (speakError != null) {
      throw speakError!;
    }
  }

  @override
  Future<void> stop() async {}

  void reset() {
    spokenTexts.clear();
    speakError = null;
  }
}
