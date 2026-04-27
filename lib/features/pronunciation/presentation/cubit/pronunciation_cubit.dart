import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/speech_to_text_service.dart';
import '../../../../core/services/text_to_speech_service.dart';
import '../../../learning/domain/entities/learning_item.dart';
import '../../domain/services/pronunciation_evaluator.dart';
import 'pronunciation_state.dart';

class PronunciationCubit extends Cubit<PronunciationState> {
  PronunciationCubit({
    required TextToSpeechService textToSpeechService,
    required SpeechToTextService speechToTextService,
    required PronunciationEvaluator pronunciationEvaluator,
  })  : _textToSpeechService = textToSpeechService,
        _speechToTextService = speechToTextService,
        _pronunciationEvaluator = pronunciationEvaluator,
        super(const PronunciationState());

  final TextToSpeechService _textToSpeechService;
  final SpeechToTextService _speechToTextService;
  final PronunciationEvaluator _pronunciationEvaluator;

  void selectItem(LearningItem item) {
    emit(
      state.copyWith(
        status: PronunciationStatus.initial,
        selectedItem: item,
        recognizedText: null,
        result: null,
        errorMessage: null,
      ),
    );
  }

  /// Cancels an active recording session without emitting a result.
  void cancelRecording() {
    final LearningItem? item = state.selectedItem;
    if (item == null) return;
    emit(
      PronunciationState(
        status: PronunciationStatus.initial,
        selectedItem: item,
      ),
    );
  }

  Future<void> speakSelectedText() async {
    final LearningItem? item = state.selectedItem;
    if (item == null) {
      return;
    }
    emit(
      PronunciationState(
        status: PronunciationStatus.playing,
        selectedItem: item,
      ),
    );
    try {
      await _textToSpeechService.speak(item.text);
      // Only reset if still in playing state (user might have started recording).
      if (state.status == PronunciationStatus.playing) {
        emit(
          PronunciationState(
            status: PronunciationStatus.initial,
            selectedItem: item,
          ),
        );
      }
    } catch (_) {
      emit(
        PronunciationState(
          status: PronunciationStatus.failure,
          selectedItem: item,
          errorMessage: 'No se pudo reproducir el audio.',
        ),
      );
    }
  }

  Future<void> captureAndEvaluate() async {
    final LearningItem? item = state.selectedItem;
    if (item == null) {
      return;
    }

    emit(
      state.copyWith(
        status: PronunciationStatus.listening,
        recognizedText: null,
        result: null,
        errorMessage: null,
      ),
    );

    try {
      final String? spoken = await _speechToTextService.listenOnce();
      // Guard: user may have cancelled while we were listening.
      if (state.status != PronunciationStatus.listening) return;
      if (spoken == null || spoken.isEmpty) {
        emit(
          state.copyWith(
            status: PronunciationStatus.failure,
            errorMessage: 'No se detecto voz. Intenta de nuevo.',
          ),
        );
        return;
      }
      final pronunciationResult = _pronunciationEvaluator.evaluate(
        expected: item.text,
        spoken: spoken,
      );
      emit(
        state.copyWith(
          status: PronunciationStatus.result,
          recognizedText: spoken,
          result: pronunciationResult,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PronunciationStatus.failure,
          errorMessage: 'No se pudo procesar la pronunciacion.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _speechToTextService.stop();
    await _textToSpeechService.stop();
    return super.close();
  }
}
