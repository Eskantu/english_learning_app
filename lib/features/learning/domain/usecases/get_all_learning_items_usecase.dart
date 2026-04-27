import '../entities/learning_item.dart';
import '../repositories/learning_repository.dart';

class GetAllLearningItemsUseCase {
  const GetAllLearningItemsUseCase(this._repository);

  final LearningRepository _repository;

  Future<List<LearningItem>> call() => _repository.getAllItems();
}
