import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../learning/presentation/cubit/learning_items_cubit.dart';
import '../../domain/entities/review_quality.dart';
import '../cubit/review_cubit.dart';
import '../cubit/review_state.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

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
        return Scaffold(
          appBar: AppBar(
            title: Text('Repaso ${state.currentIndex + 1}/${state.items.length}'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.text,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.meaning,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () => context.read<ReviewCubit>().submitAnswer(ReviewQuality.forgot),
                  child: const Text('No recorde'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => context.read<ReviewCubit>().submitAnswer(ReviewQuality.partial),
                  child: const Text('Mas o menos'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => context.read<ReviewCubit>().submitAnswer(ReviewQuality.easy),
                  child: const Text('Facil'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
