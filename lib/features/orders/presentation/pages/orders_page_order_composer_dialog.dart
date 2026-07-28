part of 'orders_page.dart';

class _OrderComposerDialog extends ConsumerStatefulWidget {
  const _OrderComposerDialog({this.order, this.initialTableId});
  final RestaurantOrder? order;
  final String? initialTableId;
  @override
  ConsumerState<_OrderComposerDialog> createState() =>
      _OrderComposerDialogState();
}

class _OrderComposerDialogState extends ConsumerState<_OrderComposerDialog> {
  final Map<String, int> _quantities = {};
  RestaurantOrderType _type = RestaurantOrderType.dineIn;
  String? _tableId;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    if (order != null) {
      _type = order.orderType;
      _tableId = order.tableId;
      for (final line in order.items) {
        if (line.menuItemId != null) {
          _quantities[line.menuItemId!] = line.quantity.toInt();
        }
      }
    } else if (widget.initialTableId != null) {
      _tableId = widget.initialTableId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(restaurantTablesProvider);
    final menu = ref.watch(menuCatalogProvider);
    final mutation = ref.watch(orderMutationControllerProvider);
    return AlertDialog(
      title: Text(widget.order == null ? 'New order' : 'Edit order'),
      content: SizedBox(
        width: 720,
        child: menu.when(
          loading: () => const TavolaLoadingIndicator(label: 'Loading menu…'),
          error: (_, _) =>
              const Text('Menu is unavailable. Try again shortly.'),
          data: (catalog) => _composerContent(
            tables.asData?.value ?? const [],
            catalog,
            mutation,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: mutation.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.order == null)
          OutlinedButton(
            onPressed: mutation.isLoading
                ? null
                : () => _submit(sendToKitchen: true),
            child: const Text('Create & send to kitchen'),
          ),
        FilledButton(
          onPressed: mutation.isLoading ? null : () => _submit(),
          child: Text(widget.order == null ? 'Create order' : 'Save order'),
        ),
      ],
    );
  }

  Widget _composerContent(
    List<DiningTable> tables,
    MenuCatalog catalog,
    AsyncValue<void> mutation,
  ) {
    final scopedTables = tables
        .where((table) => table.status != DiningTableStatus.unavailable)
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: TavolaSpace.md,
          runSpacing: TavolaSpace.sm,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<RestaurantOrderType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Order type'),
                items: RestaurantOrderType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
            ),
            if (_type == RestaurantOrderType.dineIn)
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: _tableId,
                  decoration: const InputDecoration(labelText: 'Table'),
                  items: scopedTables
                      .map(
                        (table) => DropdownMenuItem(
                          value: table.id,
                          child: Text(table.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _tableId = value),
                ),
              ),
          ],
        ),
        const SizedBox(height: TavolaSpace.md),
        SizedBox(
          height: 360,
          child: ListView(
            children: catalog.items
                .where((item) => item.isAvailable)
                .map(_menuRow)
                .toList(),
          ),
        ),
        if (mutation.isLoading) const LinearProgressIndicator(),
        if (mutation.hasError)
          Padding(
            padding: const EdgeInsets.only(top: TavolaSpace.sm),
            child: Text(
              'Could not create this order. ${mutation.error}',
              style: const TextStyle(color: TavolaColors.error),
            ),
          ),
      ],
    );
  }

  Widget _menuRow(MenuItem item) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(item.name),
    subtitle: Text(AppFormatters.currency.format(item.priceMinor / 100)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: (_quantities[item.id] ?? 0) == 0
              ? null
              : () => setState(
                  () => _quantities[item.id] = _quantities[item.id]! - 1,
                ),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('${_quantities[item.id] ?? 0}'),
        IconButton(
          onPressed: () => setState(
            () => _quantities[item.id] = (_quantities[item.id] ?? 0) + 1,
          ),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    ),
  );

  Future<void> _submit({bool sendToKitchen = false}) async {
    final membership = await ref.read(currentMembershipProvider.future);
    if (membership == null) {
      _showValidation('Select a restaurant before opening an order.');
      return;
    }
    final items = _quantities.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) =>
              OrderItemInput(menuItemId: entry.key, quantity: entry.value),
        )
        .toList();
    final tableId = _type == RestaurantOrderType.dineIn ? _tableId : null;
    if (items.isEmpty) {
      _showValidation('Add at least one available menu item.');
      return;
    }
    if (_type == RestaurantOrderType.dineIn && tableId == null) {
      _showValidation('Select a table for a dine-in order.');
      return;
    }
    if (widget.order case final order?) {
      await ref
          .read(orderMutationControllerProvider.notifier)
          .save(
            UpdateOrderInput(
              orderId: order.id,
              restaurantId: membership.restaurantId,
              orderType: _type,
              tableId: tableId,
              items: items,
            ),
          );
    } else {
      final input = CreateOrderInput(
        restaurantId: membership.restaurantId,
        orderType: _type,
        tableId: tableId,
        items: items,
      );
      final controller = ref.read(orderMutationControllerProvider.notifier);
      await (sendToKitchen
          ? controller.createAndSendToKitchen(input)
          : controller.create(input));
    }
    if (mounted && !ref.read(orderMutationControllerProvider).hasError) {
      Navigator.pop(context);
    }
  }

  void _showValidation(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
