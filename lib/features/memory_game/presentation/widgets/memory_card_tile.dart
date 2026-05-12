import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../domain/models/memory_card.dart';
import '../models/particle_spec.dart';
import '../painters/match_particles_painter.dart';

class MemoryCardTile extends StatefulWidget {
  const MemoryCardTile({
    super.key,
    required this.card,
    required this.enabled,
    required this.showWrongFlash,
    required this.onSpeak,
    required this.onTap,
  });

  final MemoryCard card;
  final bool enabled;
  final bool showWrongFlash;
  final Future<void> Function() onSpeak;
  final VoidCallback onTap;

  @override
  State<MemoryCardTile> createState() => _MemoryCardTileState();
}

class _MemoryCardTileState extends State<MemoryCardTile>
    with TickerProviderStateMixin {
  double _matchScale = 1;
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  late final AnimationController _particleController;
  late final List<ParticleSpec> _particles;

  bool get _isFrontVisible => !(widget.card.isFlipped || widget.card.isMatched);

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _isFrontVisible ? 0 : 1,
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _particles = _buildParticles();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MemoryCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool shouldShowFront =
        !(widget.card.isFlipped || widget.card.isMatched);
    if (shouldShowFront) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }

    if (!oldWidget.showWrongFlash && widget.showWrongFlash) {
      HapticFeedback.lightImpact();
    }

    if (!oldWidget.card.isMatched && widget.card.isMatched) {
      HapticFeedback.mediumImpact();
      _runMatchPulse();
      _particleController.forward(from: 0);
    }
  }

  Future<void> _runMatchPulse() async {
    if (!mounted) return;
    setState(() => _matchScale = 1.05);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    setState(() => _matchScale = 1.0);
  }

  List<ParticleSpec> _buildParticles() {
    final math.Random random = math.Random(widget.card.id.hashCode);
    final List<Color> palette = <Color>[
      const Color(0xFF7EA6FF),
      const Color(0xFFBFA8FF),
      const Color(0xFFA2D9A5),
    ];

    return List<ParticleSpec>.generate(10, (int index) {
      final double angle = (index / 10) * math.pi * 2;
      final double distance = 18 + random.nextDouble() * 24;
      return ParticleSpec(
        angle: angle,
        distance: distance,
        radius: 2.2 + random.nextDouble() * 1.8,
        color: palette[index % palette.length],
      );
    });
  }

  Future<void> _onCardTap() async {
    await HapticFeedback.lightImpact();
    widget.onTap();
  }

  Widget _buildFrontCard() {
    return AnimatedContainer(
      key: ValueKey<String>('front_${widget.card.id}'),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF7EA6FF).withValues(alpha: 0.85),
            const Color(0xFFBFA8FF).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft(alpha: 0.08),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Text(
              '?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.26),
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(
              Icons.psychology_alt_rounded,
              size: 30,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(Color borderColor, Color openBackground) {
    return AnimatedContainer(
      key: ValueKey<String>('back_${widget.card.id}'),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: openBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: AppShadows.soft(alpha: 0.03),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                widget.card.value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onSpeak,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 20,
                  color: borderColor.withValues(alpha: 0.78),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MemoryCard card = widget.card;
    final bool isMatched = card.isMatched;
    final bool isBase = card.type == MemoryCardType.base;

    final Color borderColor =
        isMatched
            ? const Color(0xFF4CAF50)
            : (isBase ? const Color(0xFF7EA6FF) : const Color(0xFF9AA3B2));
    final Color openBackground =
        isMatched
            ? const Color(0xFFDFF5E3)
            : (widget.showWrongFlash
                ? const Color(0xFFFDEAEA)
                : const Color(0xFFF4F6FB));

    return RepaintBoundary(
      child: AnimatedScale(
        scale: _matchScale,
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeInOut,
        child: Opacity(
          opacity: isMatched ? 0.78 : 1,
          child: GestureDetector(
            onTap: widget.enabled && !isMatched ? _onCardTap : null,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (BuildContext context, Widget? child) {
                    // 3D flip card transform around Y axis.
                    final double angle = _flipAnimation.value * math.pi;
                    final bool isUnder = angle > (math.pi / 2);

                    final Matrix4 transform =
                        Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle);

                    Widget currentFace =
                        isUnder
                            ? _buildBackCard(borderColor, openBackground)
                            : _buildFrontCard();

                    if (isUnder) {
                      currentFace = Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: currentFace,
                      );
                    }

                    return Transform(
                      alignment: Alignment.center,
                      transform: transform,
                      child: currentFace,
                    );
                  },
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _particleController,
                      builder: (BuildContext context, Widget? child) {
                        if (_particleController.value <= 0 ||
                            _particleController.isDismissed) {
                          return const SizedBox.shrink();
                        }
                        return CustomPaint(
                          painter: MatchParticlesPainter(
                            progress: _particleController.value,
                            particles: _particles,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
