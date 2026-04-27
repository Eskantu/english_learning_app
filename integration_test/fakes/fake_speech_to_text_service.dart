import 'package:english_learning_ap/core/services/speech_to_text_service.dart';

class FakeSpeechToTextService implements SpeechToTextService {
  final List<Future<String?> Function()> _pendingResponses =
      <Future<String?> Function()>[];

  int listenCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> listenOnce() async {
    listenCount++;
    if (_pendingResponses.isEmpty) {
      return null;
    }
    final Future<String?> Function() next = _pendingResponses.removeAt(0);
    return next();
  }

  @override
  Future<void> stop() async {}

  void enqueueResult(String? text) {
    _pendingResponses.add(() async => text);
  }

  void enqueueError([Object? error]) {
    _pendingResponses.add(() async => throw (error ?? Exception('fake-stt')));
  }

  void enqueueDeferredResult(Future<String?> future) {
    _pendingResponses.add(() => future);
  }

  void reset() {
    _pendingResponses.clear();
    listenCount = 0;
  }
}
