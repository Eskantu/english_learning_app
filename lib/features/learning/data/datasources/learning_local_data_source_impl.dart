import 'package:hive/hive.dart';

import '../models/learning_item_model.dart';
import 'learning_local_data_source.dart';

class LearningLocalDataSourceImpl implements LearningLocalDataSource {
  LearningLocalDataSourceImpl({required Box<LearningItemModel> learningBox})
      : _learningBox = learningBox;

  final Box<LearningItemModel> _learningBox;

  @override
  Future<void> deleteItem(String id) async {
    await _learningBox.delete(id);
  }

  @override
  Future<List<LearningItemModel>> getAllItems() async {
    final List<LearningItemModel> items = _learningBox.values.toList(growable: false);
    items.sort((LearningItemModel a, LearningItemModel b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  @override
  Future<List<LearningItemModel>> getItemsToReview(DateTime onDate) async {
    final DateTime limit = DateTime(onDate.year, onDate.month, onDate.day, 23, 59, 59);
    return _learningBox.values
        .where((LearningItemModel item) => !item.nextReviewDate.isAfter(limit))
        .toList(growable: false);
  }

  @override
  Future<void> saveItem(LearningItemModel item) async {
    await _learningBox.put(item.id, item);
  }

  @override
  Future<void> updateItem(LearningItemModel item) async {
    await _learningBox.put(item.id, item);
  }
}
