import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/pronunciation_result.dart';

class ResultWidget extends StatelessWidget {
  const ResultWidget({
    super.key,
    required this.recognizedText,
    required this.originalPhrase,
    required this.result,
    required this.compact,
  });

  final String recognizedText;
  final String originalPhrase;
  final PronunciationResult result;
  final bool compact;

  Color get _scoreColor => switch (result.feedback) {
    PronunciationFeedback.correct => AppColors.success,
    PronunciationFeedback.almostCorrect => AppColors.warning,
    PronunciationFeedback.incorrect => AppColors.error,
  };

  String get _headline => switch (result.feedback) {
    PronunciationFeedback.correct => '¡Buen trabajo!',
    PronunciationFeedback.almostCorrect => '¡Casi!',
    PronunciationFeedback.incorrect => 'Inténtalo de nuevo',
  };

  String get _badgeLabel => switch (result.feedback) {
    PronunciationFeedback.correct => 'Muy bien',
    PronunciationFeedback.almostCorrect => 'Casi correcto',
    PronunciationFeedback.incorrect => 'Sigue practicando',
  };

  String get _badgeSubtitle => switch (result.feedback) {
    PronunciationFeedback.correct => 'Tu pronunciación es muy similar.',
    PronunciationFeedback.almostCorrect => 'Sigue practicando un poco más.',
    PronunciationFeedback.incorrect =>
      'La pronunciación necesita más práctica.',
  };

  IconData get _badgeIcon => switch (result.feedback) {
    PronunciationFeedback.correct => Icons.check_circle_rounded,
    PronunciationFeedback.almostCorrect => Icons.remove_circle_outline_rounded,
    PronunciationFeedback.incorrect => Icons.cancel_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final int scoreInt = (result.score * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _scoreColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.all(compact ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Resultado',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: compact ? 16 : 22),
          Center(
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: result.score,
                      strokeWidth: 9,
                      color: _scoreColor,
                      backgroundColor: _scoreColor.withValues(alpha: 0.15),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '$scoreInt',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _scoreColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _headline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: compact ? 16 : 20),
          _ResultRow(
            label: 'Tu dijiste:',
            text: recognizedText,
            highlight: true,
            color: _scoreColor,
          ),
          const SizedBox(height: 10),
          _ResultRow(label: 'Frase correcta:', text: originalPhrase),
          SizedBox(height: compact ? 14 : 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _scoreColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                Icon(_badgeIcon, color: _scoreColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _badgeLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _scoreColor,
                        ),
                      ),
                      Text(
                        _badgeSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.text,
    this.highlight = false,
    this.color,
  });

  final String label;
  final String text;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                highlight && color != null
                    ? color!.withValues(alpha: 0.10)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  highlight && color != null
                      ? color!
                      : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
