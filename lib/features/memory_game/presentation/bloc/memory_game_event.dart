import 'package:equatable/equatable.dart';

import '../../../learning/domain/entities/learning_item.dart';

abstract class MemoryGameEvent extends Equatable {
  const MemoryGameEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class InitializeGame extends MemoryGameEvent {
  const InitializeGame(this.verbs);

  final List<LearningItem> verbs;

  @override
  List<Object?> get props => <Object?>[verbs];
}

class FlipCard extends MemoryGameEvent {
  const FlipCard(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}

class ResetGame extends MemoryGameEvent {
  const ResetGame();
}
