import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../learning/presentation/cubit/learning_items_cubit.dart';
import '../../domain/entities/review_quality.dart';
import '../cubit/review_cubit.dart';
import '../cubit/review_state.dart';
import '../widgets/review_widgets.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String? _revealedItemId;

  @override
  void dispose() {
    unawaited(ServiceLocator.textToSpeechService.dispose());
    super.dispose();
  }

  bool _isMeaningRevealed(String itemId) => _revealedItemId == itemId;

  void _toggleReveal(String itemId) {
    setState(() {
      _revealedItemId = _revealedItemId == itemId ? null : itemId;
    });
  }

  Future<void> _speakText(String text) async {
    await ServiceLocator.textToSpeechService.speak(text);
  }

  void _submitAnswer(ReviewQuality quality) {
    setState(() => _revealedItemId = null);
    context.read<ReviewCubit>().submitAnswer(quality);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReviewCubit, ReviewState>(
      listener: (BuildContext context, ReviewState state) {
        if (state.status == ReviewStatus.completed) {
          context.read<LearningItemsCubit>().loadItems();
        }
      },
      builder: (BuildContext context, ReviewState state) {
        if (state.status == ReviewStatus.loading || state.status == ReviewStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == ReviewStatus.failure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Repaso')),
            body: Center(
              child: Text(state.errorMessage ?? 'Ocurrio un error.'),
            ),
          );
        }

        if (state.status == ReviewStatus.completed || state.currentItem == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Repaso')),
            body: const Center(
              child: Text('No tienes elementos pendientes para hoy.'),
            ),
          );
        }

        final item = state.currentItem!;
        final String? hint =
            item.examples.isNotEmpty ? item.examples.first : null;

        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxHeight < 780;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 20,
                        compact ? 10 : 14,
                        compact ? 16 : 20,
                        compact ? 16 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(height: compact ? 2 : 8),
                          ReviewHeader(
                            currentIndex: state.currentIndex,
                            total: state.items.length,
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 14 : 20),
                          ReviewFlashcard(
                            phrase: item.text,
                            meaning: item.meaning,
                            revealed: _isMeaningRevealed(item.id),
                            onToggleReveal: () => _toggleReveal(item.id),
                            onSpeak: () => _speakText(item.text),
                            compact: compact,
                          ),
                          if (hint != null) ...<Widget>[
                            SizedBox(height: compact ? 10 : 12),
                            Text(
                              '💡 Pista: $hint',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                          SizedBox(height: compact ? 14 : 18),
                          Text(
                            '¿Cómo te fue?',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Selecciona la opcion que mejor describa tu recuerdo.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          AnswerOptionCard(
                            title: 'No recordé',
                            subtitle: 'No la recordaba en absoluto',
                            icon: Icons.sentiment_dissatisfied_rounded,
                            background: AppColors.error.withValues(alpha: 0.10),
                            foreground: AppColors.error,
                            onTap: () => _submitAnswer(ReviewQuality.forgot),
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 8 : 10),
                          AnswerOptionCard(
                            title: 'Más o menos',
                            subtitle: 'La recordaba con dificultad',
                            icon: Icons.sentiment_neutral_rounded,
                            background: AppColors.warning.withValues(
                              alpha: 0.12,
                            ),
                            foreground: AppColors.warning,
                            onTap: () => _submitAnswer(ReviewQuality.partial),
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 8 : 10),
                          AnswerOptionCard(
                            title: 'Fácil',
                            subtitle: 'La recordé sin problema',
                            icon: Icons.sentiment_very_satisfied_rounded,
                            background: AppColors.success.withValues(
                              alpha: 0.12,
                            ),
                            foreground: AppColors.success,
                            onTap: () => _submitAnswer(ReviewQuality.easy),
                            compact: compact,
                          ),
                          // SizedBox(height: compact ? 12 : 14),
                          // _MotivationCard(
                          //   title: '🏆 ¡Tú puedes!',
                          //   subtitle: 'La práctica diaria te hace mejor cada día.',
                          //   compact: compact,
                          // ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

