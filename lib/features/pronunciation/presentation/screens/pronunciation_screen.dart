import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../learning/domain/entities/learning_item.dart';
import '../cubit/pronunciation_cubit.dart';
import '../cubit/pronunciation_state.dart';
import '../../domain/entities/pronunciation_result.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key, required this.items});

  final List<LearningItem> items;

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> {
  LearningItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    if (widget.items.isNotEmpty) {
      _selectedItem = widget.items.first;
      context.read<PronunciationCubit>().selectItem(_selectedItem!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pronunciacion')),
      body: BlocBuilder<PronunciationCubit, PronunciationState>(
        builder: (BuildContext context, PronunciationState state) {
          if (widget.items.isEmpty) {
            return const Center(child: Text('No hay frases para practicar.'));
          }

          final String feedbackText = switch (state.result?.feedback) {
            PronunciationFeedback.correct => 'Correcto',
            PronunciationFeedback.almostCorrect => 'Casi correcto',
            PronunciationFeedback.incorrect => 'Incorrecto',
            null => '',
          };

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DropdownButtonFormField<LearningItem>(
                  value: _selectedItem,
                  items: widget.items
                      .map(
                        (LearningItem item) => DropdownMenuItem<LearningItem>(
                          value: item,
                          child: Text(
                            item.text,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (LearningItem? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedItem = value);
                    context.read<PronunciationCubit>().selectItem(value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Frase a practicar',
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      state.selectedItem?.text ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      () =>
                          context
                              .read<PronunciationCubit>()
                              .speakSelectedText(),
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Escuchar frase (TTS)'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed:
                      state.status == PronunciationStatus.listening
                          ? null
                          : () =>
                              context
                                  .read<PronunciationCubit>()
                                  .captureAndEvaluate(),
                  icon: const Icon(Icons.mic),
                  label: Text(
                    state.status == PronunciationStatus.listening
                        ? 'Escuchando...'
                        : 'Grabar y evaluar (STT)',
                  ),
                ),
                const SizedBox(height: 24),
                if (state.recognizedText != null)
                  Text('Tu voz: ${state.recognizedText}'),
                if (state.result != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('Resultado: $feedbackText'),
                  Text(
                    'Similitud: ${(state.result!.score * 100).toStringAsFixed(1)}%',
                  ),
                ],
                if (state.status == PronunciationStatus.failure)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.errorMessage ?? 'Ocurrio un error.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
