import 'package:equatable/equatable.dart';

import '../../domain/entities/learning_item.dart';

enum LearningItemsStatus { initial, loading, success, failure }

class LearningItemsState extends Equatable {
  const LearningItemsState({
    this.status = LearningItemsStatus.initial,
    this.items = const <LearningItem>[],
    this.errorMessage,
  });

  final LearningItemsStatus status;
  final List<LearningItem> items;
  final String? errorMessage;

  LearningItemsState copyWith({
    LearningItemsStatus? status,
    List<LearningItem>? items,
    String? errorMessage,
  }) {
    return LearningItemsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
