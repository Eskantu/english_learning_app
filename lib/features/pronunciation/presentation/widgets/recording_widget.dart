import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class RecordingWidget extends StatelessWidget {
  const RecordingWidget({super.key, required this.micPulse});

  final AnimationController micPulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: micPulse,
      builder: (BuildContext context, Widget? child) {
        final double scale = 1.0 + 0.20 * micPulse.value;
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.scale(
              scale: scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.secondaryDark,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.22),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.mic_rounded,
          color: Theme.of(context).colorScheme.onSecondary,
          size: 38,
        ),
      ),
    );
  }
}

class WaveformWidget extends StatelessWidget {
  const WaveformWidget({
    super.key,
    required this.controller,
    required this.barCount,
    required this.phaseOffset,
  });

  final AnimationController controller;
  final int barCount;
  final double phaseOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List<Widget>.generate(barCount, (int i) {
            final double phase = phaseOffset + (i / barCount) * math.pi * 2;
            final double value =
                (math.sin(controller.value * math.pi * 2 + phase) + 1) / 2;
            final double height = 12 + value * 28;
            return Container(
              width: 4,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        );
      },
    );
  }
}
