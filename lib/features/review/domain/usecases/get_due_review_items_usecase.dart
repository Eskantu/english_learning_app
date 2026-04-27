import '../../../learning/domain/entities/learning_item.dart';
import '../../../learning/domain/repositories/learning_repository.dart';

class GetDueReviewItemsUseCase {
  const GetDueReviewItemsUseCase(this._repository);

  final LearningRepository _repository;

  Future<List<LearningItem>> call(DateTime onDate) {
    return _repository.getItemsToReview(onDate);
  }
}
