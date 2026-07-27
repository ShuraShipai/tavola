import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';

class MenuListCard extends StatelessWidget {
  const MenuListCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(TavolaSpace.md),
    decoration: BoxDecoration(
      color: TavolaColors.surface,
      border: Border.all(color: TavolaColors.border),
      borderRadius: TavolaRadius.large,
      boxShadow: const [
        BoxShadow(
          color: TavolaColors.shadow,
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: child,
  );
}
