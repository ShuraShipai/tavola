import 'package:flutter/material.dart';

import '../../../../core/design/tavola_tokens.dart';
import 'menu_tab.dart';

class MenuTabs extends StatelessWidget {
  const MenuTabs({required this.onCategories, super.key});

  final VoidCallback onCategories;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const MenuTab(label: 'Menu items', active: true),
      const SizedBox(width: TavolaSpace.xs),
      MenuTab(label: 'Categories', onPressed: onCategories),
    ],
  );
}
