import 'package:flutter/material.dart';

import '../../domain/entities/pronunciation_result.dart';
import 'pronunciation_screen_header.dart';
import 'result_widget.dart';

class PronunciationResultView extends StatelessWidget {
  const PronunciationResultView({
    super.key,
    required this.recognizedText,
    required this.originalPhrase,
    required this.result,
    required this.currentIndex,
    required this.total,
    required this.isLastPhrase,
    required this.onRetry,
    required this.onNext,
  });

  final String recognizedText;
  final String originalPhrase;
  final PronunciationResult result;
  final int currentIndex;
  final int total;
  final bool isLastPhrase;
  final VoidCallback onRetry;
  final VoidCallback onNext;

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
                    total: total,
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  ResultWidget(
                    recognizedText: recognizedText,
                    originalPhrase: originalPhrase,
                    result: result,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Volver a intentar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    iconAlignment: IconAlignment.end,
                    label: Text(isLastPhrase ? 'Finalizar' : 'Siguiente frase'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
