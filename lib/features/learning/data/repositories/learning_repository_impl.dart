import '../../domain/entities/learning_item.dart';
import '../../domain/repositories/learning_repository.dart';
import '../datasources/learning_local_data_source.dart';
import '../models/learning_item_model.dart';

class LearningRepositoryImpl implements LearningRepository {
  LearningRepositoryImpl({required LearningLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  final LearningLocalDataSource _localDataSource;

  @override
  Future<void> deleteItem(String id) => _localDataSource.deleteItem(id);

  @override
  Future<List<LearningItem>> getAllItems() => _localDataSource.getAllItems();

  @override
  Future<List<LearningItem>> getItemsToReview(DateTime onDate) {
    return _localDataSource.getItemsToReview(onDate);
  }

  @override
  Future<void> saveItem(LearningItem item) {
    return _localDataSource.saveItem(LearningItemModel.fromEntity(item));
  }

  @override
  Future<void> updateItem(LearningItem item) {
    return _localDataSource.updateItem(LearningItemModel.fromEntity(item));
  }
}
