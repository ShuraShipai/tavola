import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../menu/domain/entities/menu_entities.dart';
import '../../../menu/presentation/providers/menu_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tables/domain/entities/dining_table.dart';
import '../../../tables/presentation/providers/dining_table_providers.dart';
import '../../domain/entities/restaurant_order.dart';
import '../../domain/repositories/restaurant_order_repository.dart';
import '../providers/new_order_draft_provider.dart';
import '../providers/restaurant_order_providers.dart';
import '../widgets/new_order/menu_category_tabs.dart';
import '../widgets/new_order/new_order_menu_grid.dart';
import '../widgets/new_order/new_order_ticket.dart';
import '../widgets/new_order/new_order_type_selector.dart';

/// Full-page order composer based on the desktop POS handoff.
class NewOrderPage extends ConsumerWidget {
  const NewOrderPage({this.initialTableId, super.key});

  final String? initialTableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(menuCatalogProvider);
    final tables = ref.watch(restaurantTablesProvider);
    final draft = ref.watch(newOrderDraftProvider);
    final controller = ref.read(newOrderDraftProvider.notifier);

    if (initialTableId != null && draft.tableId == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.selectTable(initialTableId),
      );
    }

    return TavolaAppShell(
      activeRoute: '/orders',
      child: catalog.when(
        loading: () => const TavolaLoadingIndicator(label: 'Loading menu…'),
        error: (error, _) => TavolaErrorState(
          message: 'We could not load the menu for this restaurant.',
          onRetry: () => ref.invalidate(menuCatalogProvider),
        ),
        data: (value) => _NewOrderContent(
          catalog: value,
          tables: tables.asData?.value ?? const [],
        ),
      ),
    );
  }
}

class _NewOrderContent extends ConsumerWidget {
  const _NewOrderContent({required this.catalog, required this.tables});

  final MenuCatalog catalog;
  final List<DiningTable> tables;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(newOrderDraftProvider);
    final draftController = ref.read(newOrderDraftProvider.notifier);
    final mutation = ref.watch(orderMutationControllerProvider);
    final items = _visibleItems(catalog, draft);
    final selectedItems = catalog.items
        .where((item) => draft.quantityFor(item.id) > 0)
        .toList();
    final lines = selectedItems.map((item) {
      final quantity = draft.quantityFor(item.id);
      final subtotal = item.priceMinor * quantity;
      final tax = (subtotal * item.taxRateBasisPoints / 10000).round();
      return OrderLine(
        menuItemId: item.id,
        name: item.name,
        unitPriceAmount: item.priceMinor,
        quantity: quantity,
        taxAmount: tax,
        lineTotalAmount: subtotal,
      );
    }).toList();
    final selectedTable = _findTable(tables, draft.tableId);
    final isCompact =
        TavolaBreakpoints.isMedium(context) ||
        TavolaBreakpoints.isCompact(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NewOrderHeader(
            draft: draft,
            selectedTable: selectedTable,
            tables: tables,
            onOrderTypeChanged: draftController.selectOrderType,
            onTableChanged: draftController.selectTable,
          ),
          const SizedBox(height: TavolaSpace.xl),
          if (isCompact)
            Column(
              children: [
                _MenuPane(
                  categories: catalog.categories
                      .where((c) => c.isOrderable)
                      .toList(),
                  items: items,
                  draft: draft,
                  onSelectCategory: draftController.selectCategory,
                  onSearch: draftController.setSearchQuery,
                  onAddItem: (item) => draftController.addItem(item.id),
                ),
                const SizedBox(height: TavolaSpace.lg),
                NewOrderTicket(
                  lines: lines,
                  taxAmount: lines.fold(0, (sum, line) => sum + line.taxAmount),
                  isSubmitting: mutation.isLoading,
                  onIncrementLine: (line) =>
                      draftController.addItem(line.menuItemId!),
                  onDecrementLine: (line) =>
                      draftController.removeItem(line.menuItemId!),
                  onSendToKitchen: () =>
                      _save(context, ref, sendToKitchen: true),
                  onHoldOrder: () => _save(context, ref, held: true),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _MenuPane(
                    categories: catalog.categories
                        .where((c) => c.isOrderable)
                        .toList(),
                    items: items,
                    draft: draft,
                    onSelectCategory: draftController.selectCategory,
                    onSearch: draftController.setSearchQuery,
                    onAddItem: (item) => draftController.addItem(item.id),
                  ),
                ),
                const SizedBox(width: TavolaSpace.lg),
                SizedBox(
                  width: 320,
                  child: NewOrderTicket(
                    lines: lines,
                    taxAmount: lines.fold(
                      0,
                      (sum, line) => sum + line.taxAmount,
                    ),
                    isSubmitting: mutation.isLoading,
                    onIncrementLine: (line) =>
                        draftController.addItem(line.menuItemId!),
                    onDecrementLine: (line) =>
                        draftController.removeItem(line.menuItemId!),
                    onSendToKitchen: () =>
                        _save(context, ref, sendToKitchen: true),
                    onHoldOrder: () => _save(context, ref, held: true),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<MenuItem> _visibleItems(MenuCatalog catalog, NewOrderDraft draft) {
    final query = draft.searchQuery.trim().toLowerCase();
    return catalog.items.where((item) {
      return item.isOrderable &&
          (draft.categoryId == null || item.categoryId == draft.categoryId) &&
          (query.isEmpty || item.name.toLowerCase().contains(query));
    }).toList();
  }

  DiningTable? _findTable(List<DiningTable> tables, String? id) => id == null
      ? null
      : tables.cast<DiningTable?>().firstWhere(
          (table) => table!.id == id,
          orElse: () => null,
        );

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    bool sendToKitchen = false,
    bool held = false,
  }) async {
    final draft = ref.read(newOrderDraftProvider);
    final membership = await ref.read(currentMembershipProvider.future);
    if (!context.mounted) return;
    if (membership == null) return;
    final items = draft.quantities.entries
        .map(
          (entry) =>
              OrderItemInput(menuItemId: entry.key, quantity: entry.value),
        )
        .toList();
    if (items.isEmpty ||
        (draft.orderType == RestaurantOrderType.dineIn &&
            draft.tableId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a table and add at least one item.'),
        ),
      );
      return;
    }
    final input = CreateOrderInput(
      restaurantId: membership.restaurantId,
      orderType: draft.orderType,
      tableId: draft.orderType == RestaurantOrderType.dineIn
          ? draft.tableId
          : null,
      items: items,
    );
    final mutation = ref.read(orderMutationControllerProvider.notifier);
    if (held) {
      await mutation.createHeld(input);
    } else if (sendToKitchen) {
      await mutation.createAndSendToKitchen(input);
    } else {
      await mutation.create(input);
    }
    if (!context.mounted) return;
    if (ref.read(orderMutationControllerProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The order could not be saved. Please try again.'),
        ),
      );
      return;
    }
    ref.read(newOrderDraftProvider.notifier).reset();
    context.go('/orders');
  }
}

class _NewOrderHeader extends StatelessWidget {
  const _NewOrderHeader({
    required this.draft,
    required this.selectedTable,
    required this.tables,
    required this.onOrderTypeChanged,
    required this.onTableChanged,
  });

  final NewOrderDraft draft;
  final DiningTable? selectedTable;
  final List<DiningTable> tables;
  final ValueChanged<RestaurantOrderType> onOrderTypeChanged;
  final ValueChanged<String?> onTableChanged;

  @override
  Widget build(BuildContext context) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('New Order', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: TavolaSpace.xxs),
        if (draft.orderType == RestaurantOrderType.dineIn)
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String>(
              initialValue: draft.tableId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Table',
                prefixIcon: Icon(Icons.table_restaurant_outlined),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: TavolaSpace.sm,
                  vertical: TavolaSpace.xs,
                ),
              ),
              hint: const Text('Select table'),
              items: tables
                  .where(
                    (table) => table.status != DiningTableStatus.unavailable,
                  )
                  .map(
                    (table) => DropdownMenuItem(
                      value: table.id,
                      child: Text(
                        table.id == selectedTable?.id
                            ? '${table.label} · selected'
                            : table.label,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onTableChanged,
            ),
          )
        else
          Text(
            draft.orderType.label,
            style: const TextStyle(color: TavolaColors.textSecondary),
          ),
      ],
    );
    final selector = NewOrderTypeSelector(
      value: draft.orderType,
      onChanged: (type) {
        onOrderTypeChanged(type);
        if (type == RestaurantOrderType.delivery) {
          context.go(AppRoutes.ordersDelivery);
        }
      },
    );
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= TavolaBreakpoints.medium
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details),
                selector,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: TavolaSpace.md),
                selector,
              ],
            ),
    );
  }
}

class _MenuPane extends StatelessWidget {
  const _MenuPane({
    required this.categories,
    required this.items,
    required this.draft,
    required this.onSelectCategory,
    required this.onSearch,
    required this.onAddItem,
  });

  final List<MenuCategory> categories;
  final List<MenuItem> items;
  final NewOrderDraft draft;
  final ValueChanged<String?> onSelectCategory;
  final ValueChanged<String> onSearch;
  final ValueChanged<MenuItem> onAddItem;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 570,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: onSearch,
          decoration: const InputDecoration(
            hintText: 'Search menu items…',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: TavolaSpace.md),
        MenuCategoryTabs(
          categories: categories,
          selectedCategoryId: draft.categoryId,
          onSelected: onSelectCategory,
        ),
        const SizedBox(height: TavolaSpace.md),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No menu items match this filter.'))
              : NewOrderMenuGrid(
                  items: items,
                  quantityForItem: (item) => draft.quantityFor(item.id),
                  onAddItem: onAddItem,
                ),
        ),
      ],
    ),
  );
}
