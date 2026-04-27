import '../entities/learning_item.dart';

abstract class LearningRepository {
  Future<List<LearningItem>> getAllItems();
  Future<List<LearningItem>> getItemsToReview(DateTime onDate);
  Future<void> saveItem(LearningItem item);
  Future<void> updateItem(LearningItem item);
  Future<void> deleteItem(String id);
}
