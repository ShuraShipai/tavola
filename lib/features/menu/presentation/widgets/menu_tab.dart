import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';

class MenuTab extends StatelessWidget {
  const MenuTab({
    required this.label,
    this.active = false,
    this.onPressed,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: IntrinsicWidth(
      child: Material(
        color: active ? TavolaColors.primary : TavolaColors.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: const BoxConstraints(minWidth: 112),
            padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? TavolaColors.primary : TavolaColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active
                    ? TavolaColors.textInverse
                    : TavolaColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
