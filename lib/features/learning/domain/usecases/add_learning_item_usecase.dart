import '../entities/learning_item.dart';
import '../repositories/learning_repository.dart';

class AddLearningItemUseCase {
  const AddLearningItemUseCase(this._repository);

  final LearningRepository _repository;

  Future<void> call(LearningItem item) => _repository.saveItem(item);
}
