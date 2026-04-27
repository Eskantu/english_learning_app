import '../repositories/learning_repository.dart';

class DeleteLearningItemUseCase {
  const DeleteLearningItemUseCase(this._repository);

  final LearningRepository _repository;

  Future<void> call(String id) => _repository.deleteItem(id);
}
