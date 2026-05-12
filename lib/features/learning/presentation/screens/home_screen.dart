import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../memory_game/presentation/screens/memory_game_screen.dart';
import '../../domain/entities/learning_item.dart';
import '../../../pronunciation/presentation/presentation.dart';
import '../../../review/presentation/presentation.dart';
import '../cubit/learning_items_cubit.dart';
import '../cubit/learning_items_state.dart';
import '../widgets/daily_progress_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/phrase_card.dart';
import '../widgets/quick_stats_row.dart';
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

  void _openMemoryGame(BuildContext context, List<LearningItem> items) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => MemoryGameScreen(verbs: items)),
    );
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
              return EmptyStateView(onAddPressed: () => _openAddEdit(context));
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
                    child: DailyProgressCard(
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
                    child: QuickStatsRow(
                      totalPhrases: totalItems,
                      practicedToday: reviewedToday,
                      streak: streak,
                    ),
                  ),
                ),
                // Memory game entry
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: OutlinedButton.icon(
                      onPressed: () => _openMemoryGame(context, state.items),
                      icon: const Icon(Icons.psychology_alt_rounded),
                      label: const Text('🧠 Memorama'),
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
