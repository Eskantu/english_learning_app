import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/particle_spec.dart';

class MatchParticlesPainter extends CustomPainter {
  const MatchParticlesPainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<ParticleSpec> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final double eased = Curves.easeOut.transform(progress);
    final double fade = (1 - progress).clamp(0, 1);
    final Offset center = Offset(size.width / 2, size.height / 2);

    for (final ParticleSpec particle in particles) {
      final double dx = math.cos(particle.angle) * particle.distance * eased;
      final double dy =
          math.sin(particle.angle) * particle.distance * eased - (8 * eased);

      final Paint paint =
          Paint()
            ..color = particle.color.withValues(alpha: 0.75 * fade)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(center + Offset(dx, dy), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MatchParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles;
  }
}
