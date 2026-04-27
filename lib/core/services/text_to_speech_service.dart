abstract class TextToSpeechService {
  Future<void> initialize();
  Future<void> speak(String text);
  Future<void> stop();
}
