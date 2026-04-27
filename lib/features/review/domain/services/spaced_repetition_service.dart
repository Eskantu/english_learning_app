import '../../../learning/domain/entities/learning_item.dart';
import '../entities/review_quality.dart';

class SpacedRepetitionService {
  LearningItem scheduleNextReview(
    LearningItem item,
    ReviewQuality quality,
  ) {
    final DateTime now = DateTime.now();

    if (quality == ReviewQuality.forgot) {
      return item.copyWith(
        repetitionLevel: 0,
        nextReviewDate: now.add(const Duration(days: 1)),
      );
    }

    final int increment = quality == ReviewQuality.easy ? 2 : 1;
    final int nextLevel = (item.repetitionLevel + increment).clamp(1, 8);
    final int intervalDays = _intervalForLevel(nextLevel);

    return item.copyWith(
      repetitionLevel: nextLevel,
      nextReviewDate: now.add(Duration(days: intervalDays)),
    );
  }

  int _intervalForLevel(int level) {
    const List<int> intervals = <int>[1, 2, 4, 7, 12, 20, 30, 45, 60];
    return intervals[level.clamp(0, intervals.length - 1)];
  }
}
