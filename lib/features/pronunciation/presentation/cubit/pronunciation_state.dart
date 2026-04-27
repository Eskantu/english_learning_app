import 'package:equatable/equatable.dart';

import '../../../learning/domain/entities/learning_item.dart';
import '../../domain/entities/pronunciation_result.dart';

enum PronunciationStatus { initial, loading, listening, result, failure }

class PronunciationState extends Equatable {
  const PronunciationState({
    this.status = PronunciationStatus.initial,
    this.selectedItem,
    this.recognizedText,
    this.result,
    this.errorMessage,
  });

  final PronunciationStatus status;
  final LearningItem? selectedItem;
  final String? recognizedText;
  final PronunciationResult? result;
  final String? errorMessage;

  PronunciationState copyWith({
    PronunciationStatus? status,
    LearningItem? selectedItem,
    String? recognizedText,
    PronunciationResult? result,
    String? errorMessage,
  }) {
    return PronunciationState(
      status: status ?? this.status,
      selectedItem: selectedItem ?? this.selectedItem,
      recognizedText: recognizedText,
      result: result,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        selectedItem,
        recognizedText,
        result,
        errorMessage,
      ];
}
