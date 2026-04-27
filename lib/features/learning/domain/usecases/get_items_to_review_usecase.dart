import '../entities/learning_item.dart';
import '../repositories/learning_repository.dart';

class GetItemsToReviewUseCase {
  const GetItemsToReviewUseCase(this._repository);

  final LearningRepository _repository;

  Future<List<LearningItem>> call(DateTime onDate) {
    return _repository.getItemsToReview(onDate);
  }
}
