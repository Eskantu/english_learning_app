abstract class SpeechToTextService {
  Future<void> initialize();
  Future<String?> listenOnce();
  Future<void> stop();
}
