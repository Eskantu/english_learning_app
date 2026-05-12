import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'pronunciation_screen_header.dart';
import 'recording_widget.dart';

class PronunciationRecordingView extends StatelessWidget {
  const PronunciationRecordingView({
    super.key,
    required this.micPulse,
    required this.waveformController,
    required this.elapsed,
    required this.currentIndex,
    required this.total,
    required this.onCancel,
  });

  final AnimationController micPulse;
  final AnimationController waveformController;
  final String elapsed;
  final int currentIndex;
  final int total;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PronunciationScreenHeader(
            title: 'Pronunciación',
            currentIndex: currentIndex,
            total: total,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              children: <Widget>[
                Text(
                  'Graba tu pronunciación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Habla ahora...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    WaveformWidget(
                      controller: waveformController,
                      barCount: 5,
                      phaseOffset: 0,
                    ),
                    const SizedBox(width: 16),
                    RecordingWidget(micPulse: micPulse),
                    const SizedBox(width: 16),
                    WaveformWidget(
                      controller: waveformController,
                      barCount: 5,
                      phaseOffset: math.pi,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  elapsed,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu grabación se convertirá en texto\ny se comparará con la frase correcta.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Icon(
                Icons.graphic_eq_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Habla claro y a un ritmo natural',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar grabación'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
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
        ],
      ),
    );
  }
}
