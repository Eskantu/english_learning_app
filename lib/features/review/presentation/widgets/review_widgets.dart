import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class ReviewHeader extends StatelessWidget {
  const ReviewHeader({
    super.key,
    required this.currentIndex,
    required this.total,
    required this.compact,
  });

  final int currentIndex;
  final int total;
  final bool compact;

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
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Repaso ${currentIndex + 1}/$total',
                style: (compact
                        ? Theme.of(context).textTheme.headlineSmall
                        : Theme.of(context).textTheme.headlineMedium)
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 12,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            );
          },
        ),
      ],
    );
  }
}

class ReviewFlashcard extends StatelessWidget {
  const ReviewFlashcard({
    super.key,
    required this.phrase,
    required this.meaning,
    required this.revealed,
    required this.onToggleReveal,
    required this.onSpeak,
    required this.compact,
  });

  final String phrase;
  final String meaning;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onSpeak;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[
              AppColors.primaryContainer,
              AppColors.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onToggleReveal,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 22,
              compact ? 14 : 20,
              compact ? 16 : 22,
              compact ? 16 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: IconButton(
                      onPressed: onSpeak,
                      icon: const Icon(Icons.volume_up_rounded),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 14),
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
                const SizedBox(height: 8),
                Text(
                  '¿Qué significa esta frase?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    final Animation<Offset> slide = Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child:
                      revealed
                          ? Text(
                            meaning,
                            key: const ValueKey<String>('revealedMeaning'),
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                          : Text(
                            'Toca la tarjeta para revelar',
                            key: const ValueKey<String>('hiddenMeaning'),
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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

class AnswerOptionCard extends StatelessWidget {
  const AnswerOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.2,
      color: background,
      shadowColor: foreground.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: <Widget>[
              Container(
                width: compact ? 42 : 50,
                height: compact ? 42 : 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: foreground.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: foreground, size: compact ? 24 : 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: (compact
                              ? Theme.of(context).textTheme.titleLarge
                              : Theme.of(context).textTheme.headlineSmall)
                          ?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: foreground, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}
