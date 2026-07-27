import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../../auth/domain/entities/restaurant_membership.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/menu_entities.dart';
import '../providers/menu_providers.dart';
import '../widgets/menu_list_card.dart';
import '../widgets/menu_filters.dart';
import '../widgets/menu_tabs.dart';

/// Searchable menu catalogue. Item creation and editing are dedicated routes so
/// staff never perform destructive actions from a crowded list.
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
            data: (catalog) => _MenuItemsList(catalog: catalog),
          ),
    ),
  );
}

class _MenuItemsList extends ConsumerStatefulWidget {
  const _MenuItemsList({required this.catalog});

  final MenuCatalog catalog;

  @override
  ConsumerState<_MenuItemsList> createState() => _MenuItemsListState();
}

class _MenuItemsListState extends ConsumerState<_MenuItemsList> {
  final _searchController = TextEditingController();
  String? _categoryId;
  MenuAvailabilityFilter _availability = MenuAvailabilityFilter.all;
  int _page = 1;
  static const _pageSize = 4;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    final filteredItems = _filteredItems(catalog);
    final pageCount = filteredItems.isEmpty
        ? 1
        : ((filteredItems.length - 1) ~/ _pageSize) + 1;
    final page = _page.clamp(1, pageCount);
    final items = filteredItems
        .skip((page - 1) * _pageSize)
        .take(_pageSize)
        .toList(growable: false);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TavolaPageHeader(
                title: 'Menu items',
                subtitle:
                    '${catalog.items.length} items across ${catalog.categories.length} categories',
                actionLabel: 'Add Menu Item',
                onAction: () => _openCreate(catalog),
              ),
              const SizedBox(height: TavolaSpace.lg),
              MenuTabs(onCategories: () => context.go('/menu/categories')),
              const SizedBox(height: TavolaSpace.lg),
              MenuListCard(
                child: Column(
                  children: [
                    MenuFilters(
                      controller: _searchController,
                      categories: catalog.categories,
                      categoryId: _categoryId,
                      availability: _availability,
                      onChanged: () => setState(() => _page = 1),
                      onCategoryChanged: (value) => setState(() {
                        _categoryId = value;
                        _page = 1;
                      }),
                      onAvailabilityChanged: (value) => setState(() {
                        _availability = value;
                        _page = 1;
                      }),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: TavolaSpace.sm),
                      child: Divider(height: 1),
                    ),
                    if (catalog.items.isEmpty)
                      const TavolaEmptyState(
                        title: 'Your menu is empty',
                        message: 'Create a menu item to start taking orders.',
                        icon: Icons.restaurant_menu_outlined,
                      )
                    else if (items.isEmpty)
                      const TavolaEmptyState(
                        title: 'No menu items match these filters',
                        message:
                            'Try another search, category, or availability filter.',
                        icon: Icons.search_off_outlined,
                      )
                    else ...[
                      _MenuItemsTable(
                        items: items,
                        catalog: catalog,
                        onEdit: _openEdit,
                        minimumRows: _pageSize,
                      ),
                      _Pagination(
                        page: page,
                        pageCount: pageCount,
                        itemCount: filteredItems.length,
                        onPageChanged: (value) => setState(() => _page = value),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MenuItem> _filteredItems(MenuCatalog catalog) {
    final query = _searchController.text.trim().toLowerCase();
    return catalog.items
        .where((item) {
          final matchesSearch =
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              (item.description?.toLowerCase().contains(query) ?? false);
          final matchesCategory =
              _categoryId == null || item.categoryId == _categoryId;
          final matchesAvailability = switch (_availability) {
            MenuAvailabilityFilter.all => true,
            MenuAvailabilityFilter.available => item.isAvailable,
            MenuAvailabilityFilter.hidden => !item.isAvailable,
          };
          return matchesSearch && matchesCategory && matchesAvailability;
        })
        .toList(growable: false);
  }

  Future<void> _openCreate(MenuCatalog catalog) async {
    if (!await _canManage()) return;
    if (!mounted) return;
    if (!catalog.categories.any((category) => category.isActive)) {
      _showMessage(
        context,
        'Create an active category before adding a menu item.',
      );
      return;
    }
    context.go('/menu/items/new');
  }

  Future<void> _openEdit(MenuItem item) async {
    if (!await _canManage()) return;
    if (!mounted) return;
    context.go('/menu/items/${item.id}/edit');
  }

  Future<bool> _canManage() async {
    final membership = await ref.read(currentMembershipProvider.future);
    if (!mounted) return false;
    if (membership == null) {
      _showMessage(context, 'Select a restaurant before managing menu items.');
      return false;
    }
    if (membership.role != TavolaRole.owner &&
        membership.role != TavolaRole.manager) {
      _showMessage(context, 'Only an owner or manager can manage menu items.');
      return false;
    }
    return true;
  }

  void _showMessage(BuildContext context, String message) =>
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
}

class _MenuItemsTable extends StatelessWidget {
  const _MenuItemsTable({
    required this.items,
    required this.catalog,
    required this.onEdit,
    required this.minimumRows,
  });

  final List<MenuItem> items;
  final MenuCatalog catalog;
  final ValueChanged<MenuItem> onEdit;
  final int minimumRows;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingTextStyle: const TextStyle(
                color: TavolaColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.48,
              ),
              dataTextStyle: const TextStyle(
                color: TavolaColors.textPrimary,
                fontSize: 14,
              ),
              headingRowHeight: 44,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 52,
              horizontalMargin: TavolaSpace.md,
              columnSpacing: TavolaSpace.xl,
              dividerThickness: 1,
              columns: const [
                DataColumn(label: Text('ITEM')),
                DataColumn(label: Text('CATEGORY')),
                DataColumn(label: Text('TYPE')),
                // The handoff uses a regular left-aligned price column. A
                // numeric DataColumn right-aligns the value into Availability.
                DataColumn(label: Text('PRICE')),
                DataColumn(label: Text('AVAILABILITY')),
                DataColumn(label: Text('ACTION')),
              ],
              rows: items
                  .map((item) => _row(context, item))
                  .toList(growable: false),
            ),
          ),
        ),
      ),
      if (items.length < minimumRows)
        SizedBox(height: (minimumRows - items.length) * 52),
    ],
  );

  DataRow _row(BuildContext context, MenuItem item) => DataRow(
    cells: [
      DataCell(
        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      DataCell(Text(_categoryName(item.categoryId))),
      DataCell(_FoodTypeBadge(value: item.foodType)),
      DataCell(Text(AppFormatters.currency.format(item.priceMinor / 100))),
      DataCell(
        _TableStatusBadge(
          label: item.isAvailable ? 'Available' : 'Unavailable',
          color: item.isAvailable
              ? TavolaColors.success
              : TavolaColors.textMuted,
        ),
      ),
      DataCell(
        OutlinedButton(
          onPressed: () => onEdit(item),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(58, 34),
            padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.sm),
            foregroundColor: TavolaColors.secondary,
            side: const BorderSide(color: TavolaColors.border),
          ),
          child: const Text('Edit'),
        ),
      ),
    ],
  );

  String _categoryName(String categoryId) {
    for (final category in catalog.categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'Uncategorised';
  }
}

class _FoodTypeBadge extends StatelessWidget {
  const _FoodTypeBadge({required this.value});
  final String? value;

  @override
  Widget build(BuildContext context) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return const Text('—');
    final (label, color) = switch (normalized) {
      'veg' || 'vegetarian' => ('Veg', TavolaColors.success),
      'non-veg' ||
      'nonveg' ||
      'non vegetarian' => ('Non-veg', TavolaColors.error),
      'vegan' => ('Vegan', TavolaColors.success),
      'beverage' => ('Beverage', TavolaColors.info),
      _ => (value!.trim(), TavolaColors.textMuted),
    };
    return _TableStatusBadge(label: label, color: color);
  }
}

class _TableStatusBadge extends StatelessWidget {
  const _TableStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TavolaSpace.xs,
        vertical: TavolaSpace.xxs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: TavolaSpace.xxs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.pageCount,
    required this.itemCount,
    required this.onPageChanged,
  });
  final int page;
  final int pageCount;
  final int itemCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = itemCount == 0
        ? 0
        : ((page - 1) * _MenuItemsListState._pageSize) + 1;
    final end = (page * _MenuItemsListState._pageSize).clamp(0, itemCount);
    final pageNumbers = _visiblePageNumbers();
    return Padding(
      padding: const EdgeInsets.only(top: TavolaSpace.sm),
      child: Row(
        children: [
          Text(
            'Showing $start–$end of $itemCount items',
            style: const TextStyle(
              fontSize: 13,
              color: TavolaColors.textSecondary,
            ),
          ),
          const Spacer(),
          _PageButton(
            icon: Icons.chevron_left,
            tooltip: 'Previous page',
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          ),
          ...pageNumbers.map(
            (pageNumber) => _PageButton(
              label: '$pageNumber',
              isActive: pageNumber == page,
              // Keep the selected page enabled so the outlined-button theme
              // does not replace its white label with disabled dark text.
              onPressed: () {
                if (pageNumber != page) onPageChanged(pageNumber);
              },
            ),
          ),
          _PageButton(
            icon: Icons.chevron_right,
            tooltip: 'Next page',
            onPressed: page < pageCount ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }

  List<int> _visiblePageNumbers() {
    if (pageCount <= 3) {
      return List<int>.generate(pageCount, (index) => index + 1);
    }
    final start = (page - 1).clamp(1, pageCount - 2);
    return List<int>.generate(3, (index) => start + index);
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    this.label,
    this.icon,
    this.tooltip,
    this.isActive = false,
    this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final String? tooltip;
  final bool isActive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: TavolaSpace.xs),
    child: SizedBox(
      width: 32,
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isActive
              ? TavolaColors.primary
              : TavolaColors.surface,
          foregroundColor: isActive
              ? TavolaColors.textInverse
              : TavolaColors.textSecondary,
          side: BorderSide(
            color: isActive ? TavolaColors.primary : TavolaColors.border,
          ),
          shape: RoundedRectangleBorder(borderRadius: TavolaRadius.small),
        ),
        child: icon == null
            ? Text(label!, style: const TextStyle(fontWeight: FontWeight.w600))
            : Icon(icon, size: 18),
      ),
    ),
  );
}
