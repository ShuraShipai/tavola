part of 'order_states_pages.dart';

class _EditableTicket extends StatelessWidget {
  const _EditableTicket({
    required this.lines,
    required this.menuItems,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
    required this.onAddItem,
  });
  final List<_EditableOrderLine> lines;
  final List<MenuItem> menuItems;
  final ValueChanged<int> onDecrease;
  final ValueChanged<int> onIncrease;
  final ValueChanged<int> onRemove;
  final ValueChanged<MenuItem> onAddItem;

  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Items in this order',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: menuItems.isEmpty
                  ? null
                  : () => _showAddItemMenu(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: TavolaSpace.sm),
        for (var index = 0; index < lines.length; index++)
          _Editable(
            line: lines[index],
            onDecrease: () => onDecrease(index),
            onIncrease: () => onIncrease(index),
            onRemove: () => onRemove(index),
          ),
        const Divider(),
        _BillLine(
          'New Total',
          AppFormatters.currency.format(
            lines.fold<int>(0, (total, line) => total + line.lineTotalAmount) /
                100,
          ),
          bold: true,
        ),
      ],
    ),
  );

  Future<void> _showAddItemMenu(BuildContext context) async {
    final item = await showModalBottomSheet<MenuItem>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: menuItems.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final menuItem = menuItems[index];
            return ListTile(
              title: Text(menuItem.name),
              subtitle: Text(
                AppFormatters.currency.format(menuItem.priceMinor / 100),
              ),
              trailing: const Icon(Icons.add_circle_outline),
              onTap: () => Navigator.pop(context, menuItem),
            );
          },
        ),
      ),
    );
    if (item != null) onAddItem(item);
  }
}
