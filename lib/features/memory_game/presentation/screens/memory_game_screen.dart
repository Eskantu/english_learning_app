import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../learning/domain/entities/learning_item.dart';
import '../../domain/models/memory_card.dart';
import '../bloc/memory_game_bloc.dart';
import '../bloc/memory_game_event.dart';
import '../bloc/memory_game_state.dart';

class MemoryGameScreen extends StatelessWidget {
  const MemoryGameScreen({super.key, required this.verbs});

  final List<LearningItem> verbs;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemoryGameBloc>(
      create: (_) => MemoryGameBloc()..add(InitializeGame(verbs)),
      child: const _MemoryGameView(),
    );
  }
}

class _MemoryGameView extends StatefulWidget {
  const _MemoryGameView();

  @override
  State<_MemoryGameView> createState() => _MemoryGameViewState();
}

class _MemoryGameViewState extends State<_MemoryGameView> {
  Future<void> _speakCardText(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    await ServiceLocator.textToSpeechService.stop();
    await ServiceLocator.textToSpeechService.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Memorama'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reiniciar',
            onPressed:
                () => context.read<MemoryGameBloc>().add(const ResetGame()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFF7F9FF), Color(0xFFEEF1FF)],
          ),
        ),
        child: BlocBuilder<MemoryGameBloc, MemoryGameState>(
          builder: (BuildContext context, MemoryGameState state) {
            if (state.cards.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Agrega al menos 2 frases para jugar Memorama.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final int columns = state.cards.length >= 16 ? 4 : 3;
            final Set<int> wrongMatchIndexes = _wrongMatchIndexes(state);
            final int matchedPairs =
                state.cards.where((MemoryCard c) => c.isMatched).length ~/ 2;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.swipe_rounded,
                          label: 'Movimientos',
                          value: '${state.moves}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.stars_rounded,
                          label: 'Pares',
                          value: '$matchedPairs/${state.cards.length ~/ 2}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: GridView.builder(
                        itemCount: state.cards.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 11,
                          crossAxisSpacing: 11,
                          childAspectRatio: 1.02,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final MemoryCard card = state.cards[index];
                          return _MemoryCardTile(
                            key: ValueKey<String>(card.id),
                            card: card,
                            enabled: !state.isChecking,
                            showWrongFlash: wrongMatchIndexes.contains(index),
                            onSpeak: () => _speakCardText(card.value),
                            onTap:
                                () => context.read<MemoryGameBloc>().add(
                                  FlipCard(index),
                                ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.isCompleted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Juego completado en ${state.moves} movimientos. ¡Bien hecho! 🎉',
                        style: Theme.of(context).textTheme.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Set<int> _wrongMatchIndexes(MemoryGameState state) {
    if (!state.isChecking || state.firstSelectedIndex == null) {
      return <int>{};
    }

    final int firstIndex = state.firstSelectedIndex!;
    if (firstIndex < 0 || firstIndex >= state.cards.length) {
      return <int>{};
    }

    final List<int> openUnmatched = <int>[];
    for (int i = 0; i < state.cards.length; i++) {
      final MemoryCard card = state.cards[i];
      if (card.isFlipped && !card.isMatched) {
        openUnmatched.add(i);
      }
    }

    if (openUnmatched.length != 2 || !openUnmatched.contains(firstIndex)) {
      return <int>{};
    }

    final int secondIndex = openUnmatched.firstWhere(
      (int i) => i != firstIndex,
      orElse: () => -1,
    );
    if (secondIndex < 0 || secondIndex >= state.cards.length) {
      return <int>{};
    }

    final MemoryCard first = state.cards[firstIndex];
    final MemoryCard second = state.cards[secondIndex];
    final bool isMatch =
        first.pairId == second.pairId && first.type != second.type;

    return isMatch ? <int>{} : <int>{firstIndex, secondIndex};
  }
}

class _MemoryCardTile extends StatefulWidget {
  const _MemoryCardTile({
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
  State<_MemoryCardTile> createState() => _MemoryCardTileState();
}

class _MemoryCardTileState extends State<_MemoryCardTile>
    with TickerProviderStateMixin {
  double _matchScale = 1;
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  late final AnimationController _particleController;
  late final List<_ParticleSpec> _particles;

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
  void didUpdateWidget(covariant _MemoryCardTile oldWidget) {
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

  List<_ParticleSpec> _buildParticles() {
    final math.Random random = math.Random(widget.card.id.hashCode);
    final List<Color> palette = <Color>[
      const Color(0xFF7EA6FF),
      const Color(0xFFBFA8FF),
      const Color(0xFFA2D9A5),
    ];

    return List<_ParticleSpec>.generate(10, (int index) {
      final double angle = (index / 10) * math.pi * 2;
      final double distance = 18 + random.nextDouble() * 24;
      return _ParticleSpec(
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
    final bool showBack = card.isFlipped || card.isMatched;
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
                          painter: _MatchParticlesPainter(
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

class _ParticleSpec {
  const _ParticleSpec({
    required this.angle,
    required this.distance,
    required this.radius,
    required this.color,
  });

  final double angle;
  final double distance;
  final double radius;
  final Color color;
}

class _MatchParticlesPainter extends CustomPainter {
  const _MatchParticlesPainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_ParticleSpec> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final double eased = Curves.easeOut.transform(progress);
    final double fade = (1 - progress).clamp(0, 1);
    final Offset center = Offset(size.width / 2, size.height / 2);

    for (final _ParticleSpec particle in particles) {
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
  bool shouldRepaint(covariant _MatchParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
