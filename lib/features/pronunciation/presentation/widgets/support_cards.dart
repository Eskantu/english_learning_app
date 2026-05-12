import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class HintCard extends StatelessWidget {
  const HintCard({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Row(
        children: <Widget>[
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Escucha la frase primero y luego repítela lo mejor posible.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon:
          loading
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surfaceContainerHighest,
                ),
              )
              : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        disabledBackgroundColor: (color ??
                Theme.of(context).colorScheme.primary)
            .withValues(alpha: 0.6),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class ConsejoCard extends StatelessWidget {
  const ConsejoCard({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.star_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Consejo',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Habla claro, a un ritmo natural y sin prisa.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text('🎧', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}
