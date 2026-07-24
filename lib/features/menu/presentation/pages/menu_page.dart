import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

/// Static menu catalogue and item-editor composition from handoff screens 30–35.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/menu',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'Menu Management',
            subtitle: 'Manage categories, items and availability',
            actionLabel: 'Add Menu Item',
          ),
          const SizedBox(height: TavolaSpace.lg),
          const Wrap(
            spacing: TavolaSpace.xs,
            runSpacing: TavolaSpace.xs,
            children: [
              _MenuTab('All items', true),
              _MenuTab('Pizza'),
              _MenuTab('Main Course'),
              _MenuTab('Beverages'),
              _MenuTab('Desserts'),
            ],
          ),
          const SizedBox(height: TavolaSpace.md),
          TavolaPanel(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search menu items',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: TavolaSpace.sm),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Filters'),
                    ),
                  ],
                ),
                const SizedBox(height: TavolaSpace.lg),
                LayoutBuilder(
                  builder: (context, c) => GridView.count(
                    crossAxisCount: c.maxWidth > 800
                        ? 3
                        : c.maxWidth > 520
                        ? 2
                        : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: TavolaSpace.md,
                    mainAxisSpacing: TavolaSpace.md,
                    childAspectRatio: 1.85,
                    children: const [
                      _MenuItem(
                        'Margherita Pizza',
                        'Pizza · Vegetarian',
                        '₹340',
                        true,
                      ),
                      _MenuItem(
                        'Truffle Mushroom Pasta',
                        'Main Course · Vegetarian',
                        '₹420',
                        true,
                      ),
                      _MenuItem(
                        'Paneer Tikka',
                        'Starters · Vegetarian',
                        '₹260',
                        true,
                      ),
                      _MenuItem('Cold Coffee', 'Beverages', '₹130', true),
                      _MenuItem('Tiramisu', 'Desserts', '₹220', false),
                      _MenuItem(
                        'Grilled Salmon',
                        'Main Course · Non-veg',
                        '₹580',
                        true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TavolaSpace.lg),
          TavolaPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Menu Item',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TavolaSpace.xxs),
                const Text('Prepare the item details and availability state.'),
                const SizedBox(height: TavolaSpace.md),
                const _MenuForm(),
                const SizedBox(height: TavolaSpace.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Save Item'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MenuTab extends StatelessWidget {
  const _MenuTab(this.label, [this.selected = false]);
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) =>
      ChoiceChip(label: Text(label), selected: selected, onSelected: (_) {});
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(this.name, this.detail, this.price, this.available);
  final String name, detail, price;
  final bool available;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: TavolaColors.border),
      borderRadius: TavolaRadius.medium,
    ),
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: TavolaColors.accentLight,
                  borderRadius: TavolaRadius.small,
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: TavolaColors.accentDark,
                ),
              ),
              const Spacer(),
              TavolaStatusBadge(
                label: available ? 'Available' : 'Hidden',
                color: available
                    ? TavolaColors.success
                    : TavolaColors.textMuted,
              ),
            ],
          ),
          const Spacer(),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(
            detail,
            style: const TextStyle(
              color: TavolaColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class _MenuForm extends StatelessWidget {
  const _MenuForm();
  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: TavolaSpace.md,
    runSpacing: TavolaSpace.md,
    children: [
      _Field('Item name', 'e.g. Truffle Mushroom Pasta', 360),
      _Field('Category', 'Main Course', 220),
      _Field('Selling price', '₹ 0.00', 180),
      _Field('Tax rate', 'GST 5%', 180),
      _Field('Description', 'Ingredients and a short description', 360),
    ],
  );
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.hint, this.width);
  final String label, hint;
  final double width;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(decoration: InputDecoration(hintText: hint)),
      ],
    ),
  );
}
