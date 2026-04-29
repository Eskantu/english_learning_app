import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/memory_game_engine.dart';
import 'memory_game_event.dart';
import 'memory_game_state.dart';

class MemoryGameBloc extends Bloc<MemoryGameEvent, MemoryGameState> {
  MemoryGameBloc({MemoryGameEngine? engine})
    : _engine = engine ?? const MemoryGameEngine(),
      super(const MemoryGameState()) {
    on<InitializeGame>(_onInitializeGame);
    on<FlipCard>(_onFlipCard);
    on<ResetGame>(_onResetGame);
  }

  final MemoryGameEngine _engine;

  void _onInitializeGame(InitializeGame event, Emitter<MemoryGameState> emit) {
    final cards = _engine.initGame(event.verbs);
    emit(
      MemoryGameState(
        sourceVerbs: event.verbs,
        cards: cards,
        firstSelectedIndex: null,
        isChecking: false,
        moves: 0,
        isCompleted: _engine.isGameComplete(cards),
      ),
    );
  }

  Future<void> _onFlipCard(
    FlipCard event,
    Emitter<MemoryGameState> emit,
  ) async {
    if (state.isChecking || state.cards.isEmpty || state.isCompleted) {
      return;
    }

    if (event.index < 0 || event.index >= state.cards.length) {
      return;
    }

    final currentCard = state.cards[event.index];
    if (currentCard.isMatched || currentCard.isFlipped) {
      return;
    }

    final flippedCards = _engine.flipCard(state.cards, event.index);

    if (state.firstSelectedIndex == null) {
      emit(
        state.copyWith(
          cards: flippedCards,
          firstSelectedIndex: event.index,
          isChecking: false,
        ),
      );
      return;
    }

    if (state.firstSelectedIndex == event.index) {
      return;
    }

    final int firstIndex = state.firstSelectedIndex!;
    final int updatedMoves = state.moves + 1;

    emit(
      state.copyWith(
        cards: flippedCards,
        isChecking: true,
        moves: updatedMoves,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (isClosed) return;

    final matchedCards = _engine.checkMatch(
      flippedCards,
      firstIndex,
      event.index,
    );
    final bool completed = _engine.isGameComplete(matchedCards);

    emit(
      state.copyWith(
        cards: matchedCards,
        clearFirstSelected: true,
        isChecking: false,
        moves: updatedMoves,
        isCompleted: completed,
      ),
    );
  }

  void _onResetGame(ResetGame event, Emitter<MemoryGameState> emit) {
    if (state.sourceVerbs.isEmpty) {
      emit(const MemoryGameState());
      return;
    }

    final cards = _engine.initGame(state.sourceVerbs);
    emit(
      state.copyWith(
        cards: cards,
        clearFirstSelected: true,
        isChecking: false,
        moves: 0,
        isCompleted: _engine.isGameComplete(cards),
      ),
    );
  }
}
