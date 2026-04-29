import 'package:equatable/equatable.dart';

import '../../../learning/domain/entities/learning_item.dart';
import '../../domain/models/memory_card.dart';

class MemoryGameState extends Equatable {
  const MemoryGameState({
    this.sourceVerbs = const <LearningItem>[],
    this.cards = const <MemoryCard>[],
    this.firstSelectedIndex,
    this.isChecking = false,
    this.moves = 0,
    this.isCompleted = false,
  });

  final List<LearningItem> sourceVerbs;
  final List<MemoryCard> cards;
  final int? firstSelectedIndex;
  final bool isChecking;
  final int moves;
  final bool isCompleted;

  MemoryGameState copyWith({
    List<LearningItem>? sourceVerbs,
    List<MemoryCard>? cards,
    int? firstSelectedIndex,
    bool clearFirstSelected = false,
    bool? isChecking,
    int? moves,
    bool? isCompleted,
  }) {
    return MemoryGameState(
      sourceVerbs: sourceVerbs ?? this.sourceVerbs,
      cards: cards ?? this.cards,
      firstSelectedIndex:
          clearFirstSelected
              ? null
              : (firstSelectedIndex ?? this.firstSelectedIndex),
      isChecking: isChecking ?? this.isChecking,
      moves: moves ?? this.moves,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    sourceVerbs,
    cards,
    firstSelectedIndex,
    isChecking,
    moves,
    isCompleted,
  ];
}
