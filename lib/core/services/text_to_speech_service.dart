abstract class TextToSpeechService {
  bool get isInitialized;
  Future<void> initializeIfNeeded();
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> dispose();
}
