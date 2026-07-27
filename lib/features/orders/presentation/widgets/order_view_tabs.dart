import 'package:flutter/material.dart';

import '../../../../core/design/tavola_tokens.dart';
import 'order_view_tab.dart';

/// Static view selector styling from the Active Orders handoff.
class OrderViewTabs extends StatelessWidget {
  const OrderViewTabs({super.key});

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: TavolaSpace.xs,
    children: [
      OrderViewTab(label: 'Active', selected: true),
      OrderViewTab(label: 'Completed'),
      OrderViewTab(label: 'History'),
      OrderViewTab(label: 'Held'),
    ],
  );
}
