import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/memory_card.dart';
import 'memory_card_tile.dart';

class MemoryGameGrid extends StatelessWidget {
  const MemoryGameGrid({
    super.key,
    required this.cards,
    required this.isChecking,
    required this.wrongMatchIndexes,
    required this.onSpeakCard,
    required this.onFlipCard,
  });

  final List<MemoryCard> cards;
  final bool isChecking;
  final Set<int> wrongMatchIndexes;
  final Future<void> Function(String text) onSpeakCard;
  final ValueChanged<int> onFlipCard;

  @override
  Widget build(BuildContext context) {
    final int columns = cards.length >= 16 ? 4 : 3;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.medium(),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm + 6),
      child: GridView.builder(
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 11,
          crossAxisSpacing: 11,
          childAspectRatio: 1.02,
        ),
        itemBuilder: (BuildContext context, int index) {
          final MemoryCard card = cards[index];
          return MemoryCardTile(
            key: ValueKey<String>(card.id),
            card: card,
            enabled: !isChecking,
            showWrongFlash: wrongMatchIndexes.contains(index),
            onSpeak: () => onSpeakCard(card.value),
            onTap: () => onFlipCard(index),
          );
        },
      ),
    );
  }
}
