import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../learning/presentation/cubit/learning_items_cubit.dart';
import '../../domain/entities/review_quality.dart';
import '../cubit/review_cubit.dart';
import '../cubit/review_state.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String? _revealedItemId;

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
                          _ReviewHeader(
                            currentIndex: state.currentIndex,
                            total: state.items.length,
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 14 : 20),
                          _ReviewFlashcard(
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
                          _AnswerOptionCard(
                            title: 'No recordé',
                            subtitle: 'No la recordaba en absoluto',
                            icon: Icons.sentiment_dissatisfied_rounded,
                            background: AppColors.error.withValues(alpha: 0.10),
                            foreground: AppColors.error,
                            onTap: () => _submitAnswer(ReviewQuality.forgot),
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 8 : 10),
                          _AnswerOptionCard(
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
                          _AnswerOptionCard(
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

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({
    required this.currentIndex,
    required this.total,
    required this.compact,
  });

  final int currentIndex;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : (currentIndex + 1) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Repaso ${currentIndex + 1}/$total',
                style: (compact
                        ? Theme.of(context).textTheme.headlineSmall
                        : Theme.of(context).textTheme.headlineMedium)
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 12,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ReviewFlashcard extends StatelessWidget {
  const _ReviewFlashcard({
    required this.phrase,
    required this.meaning,
    required this.revealed,
    required this.onToggleReveal,
    required this.onSpeak,
    required this.compact,
  });

  final String phrase;
  final String meaning;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onSpeak;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const <Color>[
              AppColors.primaryContainer,
              AppColors.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onToggleReveal,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 22,
              compact ? 14 : 20,
              compact ? 16 : 22,
              compact ? 16 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: IconButton(
                      onPressed: onSpeak,
                      icon: const Icon(Icons.volume_up_rounded),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 14),
                Text(
                  phrase,
                  textAlign: TextAlign.center,
                  style: (compact
                          ? Theme.of(context).textTheme.headlineLarge
                          : Theme.of(context).textTheme.displaySmall)
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¿Qué significa esta frase?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    final Animation<Offset> slide = Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child:
                      revealed
                          ? Text(
                            meaning,
                            key: const ValueKey<String>('revealedMeaning'),
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                          : Text(
                            'Toca la tarjeta para revelar',
                            key: const ValueKey<String>('hiddenMeaning'),
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerOptionCard extends StatelessWidget {
  const _AnswerOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.2,
      color: background,
      shadowColor: foreground.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: <Widget>[
              Container(
                width: compact ? 42 : 50,
                height: compact ? 42 : 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: foreground.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: foreground, size: compact ? 24 : 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: (compact
                              ? Theme.of(context).textTheme.titleLarge
                              : Theme.of(context).textTheme.headlineSmall)
                          ?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: foreground, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}

