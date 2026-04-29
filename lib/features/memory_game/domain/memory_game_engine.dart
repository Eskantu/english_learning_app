import 'dart:math';

import '../../learning/domain/entities/learning_item.dart';
import 'models/memory_card.dart';

class MemoryGameEngine {
  const MemoryGameEngine();

  List<MemoryCard> initGame(List<LearningItem> verbs) {
    if (verbs.isEmpty) {
      return <MemoryCard>[];
    }

    final int pairsCount = _resolvePairsCount(verbs.length);
    final List<LearningItem> selected = verbs
        .take(pairsCount)
        .toList(growable: false);

    final List<MemoryCard> cards = <MemoryCard>[];
    for (int i = 0; i < selected.length; i++) {
      final LearningItem item = selected[i];
      final String pairId = item.id.isNotEmpty ? item.id : 'pair_$i';

      cards.add(
        MemoryCard(
          id: '${pairId}_base',
          value: item.text,
          pairId: pairId,
          type: MemoryCardType.base,
        ),
      );
      cards.add(
        MemoryCard(
          id: '${pairId}_meaning',
          value: item.meaning,
          pairId: pairId,
          type: MemoryCardType.meaning,
        ),
      );
    }

    final List<MemoryCard> shuffled = List<MemoryCard>.from(cards);
    shuffled.shuffle(Random());
    return shuffled;
  }

  List<MemoryCard> flipCard(List<MemoryCard> cards, int index) {
    if (index < 0 || index >= cards.length) {
      return cards;
    }

    final MemoryCard target = cards[index];
    if (target.isMatched || target.isFlipped) {
      return cards;
    }

    return List<MemoryCard>.generate(cards.length, (int i) {
      if (i != index) {
        return cards[i];
      }
      return cards[i].copyWith(isFlipped: true);
    });
  }

  List<MemoryCard> checkMatch(
    List<MemoryCard> cards,
    int firstIndex,
    int secondIndex,
  ) {
    if (firstIndex < 0 || secondIndex < 0) {
      return cards;
    }
    if (firstIndex >= cards.length || secondIndex >= cards.length) {
      return cards;
    }
    if (firstIndex == secondIndex) {
      return cards;
    }

    final MemoryCard first = cards[firstIndex];
    final MemoryCard second = cards[secondIndex];

    final bool isMatch =
        first.pairId == second.pairId && first.type != second.type;

    return List<MemoryCard>.generate(cards.length, (int i) {
      if (i == firstIndex || i == secondIndex) {
        if (isMatch) {
          return cards[i].copyWith(isMatched: true);
        }
        return cards[i].copyWith(isFlipped: false);
      }
      return cards[i];
    });
  }

  bool isGameComplete(List<MemoryCard> cards) {
    return cards.isNotEmpty && cards.every((MemoryCard card) => card.isMatched);
  }

  int _resolvePairsCount(int availableItems) {
    if (availableItems >= 8) {
      return 8; // 4x4
    }
    if (availableItems >= 6) {
      return 6; // 3x4
    }
    return availableItems;
  }
}
