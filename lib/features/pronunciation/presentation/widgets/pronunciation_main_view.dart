import 'package:flutter/material.dart';

import '../../../learning/domain/entities/learning_item.dart';
import '../cubit/pronunciation_state.dart';
import 'phrase_selector_widget.dart';
import 'pronunciation_card.dart';
import 'pronunciation_screen_header.dart';
import 'support_cards.dart';

class PronunciationMainView extends StatelessWidget {
  const PronunciationMainView({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.state,
    required this.speakerPulse,
    required this.onSelectItem,
    required this.onSpeak,
    required this.onRecord,
  });

  final List<LearningItem> items;
  final int currentIndex;
  final PronunciationState state;
  final AnimationController speakerPulse;
  final ValueChanged<LearningItem> onSelectItem;
  final VoidCallback onSpeak;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxHeight < 700;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, compact ? 8 : 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  PronunciationScreenHeader(
                    title: 'Pronunciación',
                    currentIndex: currentIndex,
                    total: items.length,
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  Text(
                    'Frase a practicar',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PhraseSelectorWidget(
                    items: items,
                    selected: items[currentIndex],
                    onChanged: (LearningItem? v) {
                      if (v != null) onSelectItem(v);
                    },
                  ),
                  SizedBox(height: compact ? 14 : 20),
                  PronunciationCard(
                    phrase: state.selectedItem?.text ?? '',
                    speakerPulse: speakerPulse,
                    compact: compact,
                    onSpeak: onSpeak,
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  HintCard(compact: compact),
                  if (state.status == PronunciationStatus.failure)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        state.errorMessage ?? 'Ocurrió un error.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  SizedBox(height: compact ? 16 : 24),
                  ActionButton(
                    label: 'Escuchar frase (TTS)',
                    icon: Icons.volume_up_rounded,
                    onPressed: onSpeak,
                    loading: state.status == PronunciationStatus.playing,
                  ),
                  const SizedBox(height: 10),
                  ActionButton(
                    label: 'Grabar y evaluar (STT)',
                    icon: Icons.mic_rounded,
                    onPressed: onRecord,
                    color: const Color(0xFF7E6AD6),
                  ),
                  SizedBox(height: compact ? 14 : 20),
                  ConsejoCard(compact: compact),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
