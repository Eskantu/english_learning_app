import '../models/learning_item_model.dart';

abstract class LearningLocalDataSource {
  Future<List<LearningItemModel>> getAllItems();
  Future<List<LearningItemModel>> getItemsToReview(DateTime onDate);
  Future<void> saveItem(LearningItemModel item);
  Future<void> updateItem(LearningItemModel item);
  Future<void> deleteItem(String id);
}
