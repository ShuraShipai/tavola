import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';

class KitchenActiveTicketCount extends StatelessWidget {
  const KitchenActiveTicketCount({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: TavolaColors.surfaceVariant,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        '• $count active tickets',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: TavolaColors.textSecondary,
        ),
      ),
    ),
  );
}
