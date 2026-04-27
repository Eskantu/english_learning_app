import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/learning_item.dart';
import '../../../pronunciation/presentation/presentation.dart';
import '../../../review/presentation/presentation.dart';
import '../cubit/learning_items_cubit.dart';
import '../cubit/learning_items_state.dart';
import 'add_edit_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _listFadeController;

  @override
  void initState() {
    super.initState();
    _listFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _listFadeController.forward();
  }

  @override
  void dispose() {
    _listFadeController.dispose();
    super.dispose();
  }

  Future<void> _openAddEdit(
    BuildContext context, {
    LearningItem? initialItem,
  }) async {
    final LearningItem? result = await Navigator.of(context).push<LearningItem>(
      MaterialPageRoute<LearningItem>(
        builder: (_) => AddEditItemScreen(initialItem: initialItem),
      ),
    );

    if (result != null && context.mounted) {
      await context.read<LearningItemsCubit>().saveItem(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<LearningItemsCubit, LearningItemsState>(
          builder: (BuildContext context, LearningItemsState state) {
            if (state.status == LearningItemsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == LearningItemsStatus.failure) {
              return Center(
                child: Text(state.errorMessage ?? 'Ocurrio un error.'),
              );
            }

            // Calculate statistics
            final List<LearningItem> itemsToReviewToday =
                state.items
                    .where(
                      (LearningItem item) => item.nextReviewDate.isBefore(
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day + 1,
                        ),
                      ),
                    )
                    .toList();

            final int totalItems = state.items.length;
            final int reviewedToday =
                state.items
                    .where(
                      (LearningItem item) =>
                          item.nextReviewDate.year == DateTime.now().year &&
                          item.nextReviewDate.month == DateTime.now().month &&
                          item.nextReviewDate.day == DateTime.now().day,
                    )
                    .length;

            // Calculate streak (consecutive days with review)
            int streak = 0;
            for (int i = 1; i <= 365; i++) {
              final DateTime checkDate = DateTime.now().subtract(
                Duration(days: i),
              );
              final bool hasReview = state.items.any(
                (LearningItem item) =>
                    item.nextReviewDate.year == checkDate.year &&
                    item.nextReviewDate.month == checkDate.month &&
                    item.nextReviewDate.day == checkDate.day,
              );
              if (hasReview) {
                streak++;
              } else {
                break;
              }
            }

            if (state.items.isEmpty) {
              return _EmptyStateView(onAddPressed: () => _openAddEdit(context));
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                // Header with title and icons
                SliverAppBar(
                  floating: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'English Learning',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Sigue practicando todos los días 🔥',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    IconButton(
                      tooltip: 'Pronunciacion',
                      onPressed: () {
                        final List<LearningItem> items =
                            context.read<LearningItemsCubit>().state.items;
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => BlocProvider<PronunciationCubit>(
                                  create:
                                      (_) => PronunciationCubit(
                                        textToSpeechService:
                                            ServiceLocator.textToSpeechService,
                                        speechToTextService:
                                            ServiceLocator.speechToTextService,
                                        pronunciationEvaluator:
                                            ServiceLocator
                                                .pronunciationEvaluator,
                                      ),
                                  child: PronunciationScreen(items: items),
                                ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.record_voice_over_rounded),
                    ),
                    IconButton(
                      tooltip: 'Revisar hoy',
                      onPressed: () => ReviewFlowLauncher.openReview(context),
                      icon: const Icon(Icons.auto_awesome_rounded),
                    ),
                    IconButton(
                      tooltip: 'Perfil',
                      onPressed: () {},
                      icon: const Icon(Icons.account_circle_rounded),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                // Daily Progress Card
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _DailyProgressCard(
                      itemsToReview: itemsToReviewToday.length,
                      onPracticeNow:
                          () => ReviewFlowLauncher.openReview(context),
                    ),
                  ),
                ),
                // Quick Stats
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _QuickStatsRow(
                      totalPhrases: totalItems,
                      practicedToday: reviewedToday,
                      streak: streak,
                    ),
                  ),
                ),
                // Phrase List Title
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Mis frases',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                // Phrase List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((
                      BuildContext context,
                      int index,
                    ) {
                      final LearningItem item = state.items[index];
                      final bool isForReviewToday = itemsToReviewToday.contains(
                        item,
                      );
                      return FadeTransition(
                        opacity: Tween<double>(
                          begin: 0,
                          end: 1,
                        ).animate(_listFadeController),
                        child: PhraseCard(
                          item: item,
                          isForReviewToday: isForReviewToday,
                          onTap: () => _openAddEdit(context, initialItem: item),
                          onDelete:
                              () => context
                                  .read<LearningItemsCubit>()
                                  .deleteItem(item.id),
                        ),
                      );
                    }, childCount: state.items.length),
                  ),
                ),
                // Bottom spacing
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 80),
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
        tooltip: 'Agregar nueva frase',
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Progress Card
// ─────────────────────────────────────────────────────────────────────────────

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({
    required this.itemsToReview,
    required this.onPracticeNow,
  });

  final int itemsToReview;
  final VoidCallback onPracticeNow;

  @override
  Widget build(BuildContext context) {
    final double progress = itemsToReview > 0 ? 0.33 : 0.0; // Example progress

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Hoy tienes $itemsToReview frases',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      itemsToReview > 0
                          ? 'No pierdas tu racha, sigue así 💪'
                          : 'Vuelve mañana para más frases',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: itemsToReview > 0 ? onPracticeNow : null,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
              foregroundColor: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Practicar ahora',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color:
                    itemsToReview > 0
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.totalPhrases,
    required this.practicedToday,
    required this.streak,
  });

  final int totalPhrases;
  final int practicedToday;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            icon: '📚',
            title: 'Total frases',
            value: totalPhrases.toString(),
            subtitle: 'guardadas',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: '✅',
            title: 'Practicadas hoy',
            value: practicedToday.toString(),
            subtitle: 'frases',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: '🔥',
            title: 'Racha',
            value: streak.toString(),
            subtitle: 'días seguidos',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phrase Card
// ─────────────────────────────────────────────────────────────────────────────

class PhraseCard extends StatelessWidget {
  const PhraseCard({
    super.key,
    required this.item,
    required this.isForReviewToday,
    required this.onTap,
    required this.onDelete,
  });

  final LearningItem item;
  final bool isForReviewToday;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color:
                  isForReviewToday
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.outlineVariant,
              width: isForReviewToday ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  // Speaker icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.text,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.meaning,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Review badge + Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      if (isForReviewToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Hoy',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 24),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline_rounded),
                          iconSize: 18,
                          color: Theme.of(context).colorScheme.error,
                          onPressed: onDelete,
                          tooltip: 'Eliminar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State View
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('🚀', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 16),
              Text(
                'Agrega tu primera frase',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Comienza tu viaje de aprendizaje de inglés hoy.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar frase'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'o carga',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed:
                    () => context.read<LearningItemsCubit>().seedDemoItems(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cargar demo rápida'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

