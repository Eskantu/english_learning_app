import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/service_locator.dart';
import '../../../learning/domain/entities/learning_item.dart';
import '../../domain/models/memory_card.dart';
import '../bloc/memory_game_bloc.dart';
import '../bloc/memory_game_event.dart';
import '../bloc/memory_game_state.dart';
import '../widgets/memory_completion_banner.dart';
import '../widgets/memory_game_grid.dart';
import '../widgets/memory_info_chip.dart';

class MemoryGameScreen extends StatelessWidget {
  const MemoryGameScreen({super.key, required this.verbs});

  final List<LearningItem> verbs;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemoryGameBloc>(
      create: (_) => MemoryGameBloc()..add(InitializeGame(verbs)),
      child: const _MemoryGameView(),
    );
  }
}

class _MemoryGameView extends StatefulWidget {
  const _MemoryGameView();

  @override
  State<_MemoryGameView> createState() => _MemoryGameViewState();
}

class _MemoryGameViewState extends State<_MemoryGameView> {
  Future<void> _speakCardText(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    await ServiceLocator.textToSpeechService.stop();
    await ServiceLocator.textToSpeechService.speak(text);
  }

  @override
  void dispose() {
    unawaited(ServiceLocator.textToSpeechService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Memorama'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reiniciar',
            onPressed:
                () => context.read<MemoryGameBloc>().add(const ResetGame()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFF7F9FF), Color(0xFFEEF1FF)],
          ),
        ),
        child: BlocBuilder<MemoryGameBloc, MemoryGameState>(
          builder: (BuildContext context, MemoryGameState state) {
            if (state.cards.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'Agrega al menos 2 frases para jugar Memorama.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final Set<int> wrongMatchIndexes = _wrongMatchIndexes(state);
            final int matchedPairs =
                state.cards.where((MemoryCard c) => c.isMatched).length ~/ 2;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: MemoryInfoChip(
                          icon: Icons.swipe_rounded,
                          label: 'Movimientos',
                          value: '${state.moves}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: MemoryInfoChip(
                          icon: Icons.stars_rounded,
                          label: 'Pares',
                          value: '$matchedPairs/${state.cards.length ~/ 2}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + 10),
                  Expanded(
                    child: MemoryGameGrid(
                      cards: state.cards,
                      isChecking: state.isChecking,
                      wrongMatchIndexes: wrongMatchIndexes,
                      onSpeakCard: _speakCardText,
                      onFlipCard:
                          (int index) => context.read<MemoryGameBloc>().add(
                            FlipCard(index),
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.isCompleted)
                    MemoryCompletionBanner(moves: state.moves),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Set<int> _wrongMatchIndexes(MemoryGameState state) {
    if (!state.isChecking || state.firstSelectedIndex == null) {
      return <int>{};
    }

    final int firstIndex = state.firstSelectedIndex!;
    if (firstIndex < 0 || firstIndex >= state.cards.length) {
      return <int>{};
    }

    final List<int> openUnmatched = <int>[];
    for (int i = 0; i < state.cards.length; i++) {
      final MemoryCard card = state.cards[i];
      if (card.isFlipped && !card.isMatched) {
        openUnmatched.add(i);
      }
    }

    if (openUnmatched.length != 2 || !openUnmatched.contains(firstIndex)) {
      return <int>{};
    }

    final int secondIndex = openUnmatched.firstWhere(
      (int i) => i != firstIndex,
      orElse: () => -1,
    );
    if (secondIndex < 0 || secondIndex >= state.cards.length) {
      return <int>{};
    }

    final MemoryCard first = state.cards[firstIndex];
    final MemoryCard second = state.cards[secondIndex];
    final bool isMatch =
        first.pairId == second.pairId && first.type != second.type;

    return isMatch ? <int>{} : <int>{firstIndex, secondIndex};
  }
}
