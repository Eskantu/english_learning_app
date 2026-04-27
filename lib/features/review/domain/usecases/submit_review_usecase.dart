import '../../../learning/domain/entities/learning_item.dart';
import '../../../learning/domain/repositories/learning_repository.dart';
import '../entities/review_quality.dart';
import '../services/spaced_repetition_service.dart';

class SubmitReviewUseCase {
  const SubmitReviewUseCase({
    required LearningRepository repository,
    required SpacedRepetitionService spacedRepetitionService,
  })  : _repository = repository,
        _spacedRepetitionService = spacedRepetitionService;

  final LearningRepository _repository;
  final SpacedRepetitionService _spacedRepetitionService;

  Future<LearningItem> call({
    required LearningItem item,
    required ReviewQuality quality,
  }) async {
    final LearningItem updated = _spacedRepetitionService.scheduleNextReview(item, quality);
    await _repository.updateItem(updated);
    return updated;
  }
}
