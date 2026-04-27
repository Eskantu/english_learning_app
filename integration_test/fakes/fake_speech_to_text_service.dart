import 'package:english_learning_ap/core/services/speech_to_text_service.dart';

class FakeSpeechToTextService implements SpeechToTextService {
  @override
  Future<void> initialize() async {}

  @override
  Future<String?> listenOnce() async => null;

  @override
  Future<void> stop() async {}
}
