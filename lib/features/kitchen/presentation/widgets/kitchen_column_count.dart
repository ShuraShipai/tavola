import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';

class KitchenColumnCount extends StatelessWidget {
  const KitchenColumnCount({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: TavolaColors.border,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: TavolaColors.textSecondary,
        ),
      ),
    ),
  );
}
