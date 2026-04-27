import 'package:english_learning_ap/core/services/text_to_speech_service.dart';

class FakeTextToSpeechService implements TextToSpeechService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}
