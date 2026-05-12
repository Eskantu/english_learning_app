import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';

class PronunciationCard extends StatelessWidget {
  const PronunciationCard({
    super.key,
    required this.phrase,
    required this.speakerPulse,
    required this.compact,
    required this.onSpeak,
  });

  final String phrase;
  final AnimationController speakerPulse;
  final bool compact;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primarySoft,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(compact ? 20 : 28),
      child: Column(
        children: <Widget>[
          AnimatedBuilder(
            animation: speakerPulse,
            builder: (BuildContext context, Widget? child) {
              return Transform.scale(
                scale: 1.0 + 0.12 * speakerPulse.value,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: onSpeak,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.22),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.secondaryDark,
                  size: 28,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            phrase,
            textAlign: TextAlign.center,
            style: (compact
                    ? Theme.of(context).textTheme.headlineLarge
                    : Theme.of(context).textTheme.displaySmall)
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '¿Cómo suena esta frase?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}
