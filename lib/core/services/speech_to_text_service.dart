abstract class SpeechToTextService {
  bool get isInitialized;
  Future<void> initializeIfNeeded();
  Future<String?> listenOnce();
  Future<void> stop();
  Future<void> dispose();
}
