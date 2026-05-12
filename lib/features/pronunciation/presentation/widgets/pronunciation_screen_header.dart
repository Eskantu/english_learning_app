import 'package:flutter/material.dart';

import '../../../../../core/theme/app_durations.dart';

class PronunciationScreenHeader extends StatelessWidget {
  const PronunciationScreenHeader({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.total,
  });

  final String title;
  final int currentIndex;
  final int total;

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
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.bar_chart_rounded),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: AppDurations.long,
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      color: Theme.of(context).colorScheme.primary,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${currentIndex + 1} de $total',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
