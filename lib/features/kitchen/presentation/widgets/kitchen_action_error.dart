import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';

class KitchenActionError extends StatelessWidget {
  const KitchenActionError({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: TavolaColors.error.withValues(alpha: 0.1),
        borderRadius: TavolaRadius.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(TavolaSpace.sm),
        child: Text(message, style: const TextStyle(color: TavolaColors.error)),
      ),
    ),
  );
}
