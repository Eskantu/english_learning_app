import 'package:flutter/material.dart';

import '../../../learning/domain/entities/learning_item.dart';

class PhraseSelectorWidget extends StatelessWidget {
  const PhraseSelectorWidget({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<LearningItem> items;
  final LearningItem? selected;
  final ValueChanged<LearningItem?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LearningItem>(
          value: selected,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          items: items
              .map(
                (LearningItem item) => DropdownMenuItem<LearningItem>(
                  value: item,
                  child: Text(item.text, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
