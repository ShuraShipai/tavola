import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';

/// Keeps category-dialog labels stable above their fields, matching the
/// desktop handoff instead of Material's floating-label treatment.
class CategoryField extends StatelessWidget {
  const CategoryField({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: TavolaColors.textSecondary),
      ),
      const SizedBox(height: TavolaSpace.xs),
      child,
    ],
  );
}
