import 'package:equatable/equatable.dart';

import '../../../learning/domain/entities/learning_item.dart';

enum ReviewStatus { initial, loading, success, failure, completed }

class ReviewState extends Equatable {
  const ReviewState({
    this.status = ReviewStatus.initial,
    this.items = const <LearningItem>[],
    this.currentIndex = 0,
    this.errorMessage,
  });

  final ReviewStatus status;
  final List<LearningItem> items;
  final int currentIndex;
  final String? errorMessage;

  LearningItem? get currentItem {
    if (items.isEmpty || currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex];
  }

  ReviewState copyWith({
    ReviewStatus? status,
    List<LearningItem>? items,
    int? currentIndex,
    String? errorMessage,
  }) {
    return ReviewState(
      status: status ?? this.status,
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, currentIndex, errorMessage];
}
