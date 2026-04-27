import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/learning_item.dart';
import '../../../pronunciation/presentation/presentation.dart';
import '../../../review/presentation/presentation.dart';
import '../cubit/learning_items_cubit.dart';
import '../cubit/learning_items_state.dart';
import 'add_edit_item_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      appBar: AppBar(
        title: const Text('English Learning'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Pronunciacion',
            onPressed: () {
              final List<LearningItem> items =
                  context.read<LearningItemsCubit>().state.items;
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider<PronunciationCubit>(
                    create: (_) => PronunciationCubit(
                      textToSpeechService: ServiceLocator.textToSpeechService,
                      speechToTextService: ServiceLocator.speechToTextService,
                      pronunciationEvaluator: ServiceLocator.pronunciationEvaluator,
                    ),
                    child: PronunciationScreen(items: items),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.record_voice_over),
          ),
          IconButton(
            tooltip: 'Revisar hoy',
            onPressed: () => ReviewFlowLauncher.openReview(context),
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: BlocBuilder<LearningItemsCubit, LearningItemsState>(
        builder: (BuildContext context, LearningItemsState state) {
          if (state.status == LearningItemsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == LearningItemsStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'Ocurrio un error.'),
            );
          }
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('No hay frases guardadas.'),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.read<LearningItemsCubit>().seedDemoItems(),
                    child: const Text('Cargar demo rapida'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (BuildContext context, int index) {
              final LearningItem item = state.items[index];
              return ListTile(
                title: Text(item.text),
                subtitle: Text(item.meaning),
                onTap: () => _openAddEdit(context, initialItem: item),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => context.read<LearningItemsCubit>().deleteItem(item.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEdit(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
