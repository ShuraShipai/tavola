import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/menu_entities.dart';
import '../providers/menu_providers.dart';

/// Tenant-scoped menu catalogue. Editing is introduced in a later workflow phase.
class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => TavolaAppShell(
    activeRoute: '/menu',
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: ref
          .watch(menuCatalogProvider)
          .when(
            loading: () => const TavolaLoadingIndicator(label: 'Loading menu…'),
            error: (error, _) => TavolaErrorState(
              message: 'Unable to load the menu.',
              onRetry: () => ref.invalidate(menuCatalogProvider),
            ),
            data: (catalog) => _MenuContent(catalog: catalog),
          ),
    ),
  );
}

class _MenuContent extends StatelessWidget {
  const _MenuContent({required this.catalog});
  final MenuCatalog catalog;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TavolaPageHeader(
          title: 'Menu Management',
          subtitle: 'Manage categories, items and availability',
          actionLabel: 'Add Menu Item',
        ),
        const SizedBox(height: TavolaSpace.lg),
        if (catalog.categories.isNotEmpty)
          Wrap(
            spacing: TavolaSpace.xs,
            runSpacing: TavolaSpace.xs,
            children: [
              const ChoiceChip(label: Text('All items'), selected: true),
              ...catalog.categories.map(
                (category) => ChoiceChip(
                  label: Text(category.name),
                  selected: false,
                  onSelected: (_) {},
                ),
              ),
            ],
          ),
        const SizedBox(height: TavolaSpace.md),
        if (catalog.items.isEmpty)
          const TavolaEmptyState(
            title: 'Your menu is empty',
            message: 'Create categories and menu items to start taking orders.',
            icon: Icons.restaurant_menu_outlined,
          )
        else
          TavolaPanel(
            child: LayoutBuilder(
              builder: (context, box) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: catalog.items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: box.maxWidth > 800
                      ? 3
                      : box.maxWidth > 520
                      ? 2
                      : 1,
                  crossAxisSpacing: TavolaSpace.md,
                  mainAxisSpacing: TavolaSpace.md,
                  childAspectRatio: 1.85,
                ),
                itemBuilder: (context, index) => _MenuItemCard(
                  item: catalog.items[index],
                  categoryName: _categoryName(
                    catalog,
                    catalog.items[index].categoryId,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
  String _categoryName(MenuCatalog catalog, String id) {
    for (final category in catalog.categories) {
      if (category.id == id) return category.name;
    }
    return 'Uncategorised';
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item, required this.categoryName});
  final MenuItem item;
  final String categoryName;
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
                label: item.isAvailable ? 'Available' : 'Hidden',
                color: item.isAvailable
                    ? TavolaColors.success
                    : TavolaColors.textMuted,
              ),
            ],
          ),
          const Spacer(),
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(
            '$categoryName${item.foodType == null ? '' : ' · ${item.foodType}'}',
            style: const TextStyle(
              color: TavolaColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${(item.priceMinor / 100).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}
