part of 'order_states_pages.dart';

class _Editable extends StatelessWidget {
  const _Editable({
    required this.line,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });
  final _EditableOrderLine line;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TavolaSpace.sm),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${line.notes?.isNotEmpty == true ? '${line.notes} · ' : ''}${AppFormatters.currency.format(line.unitPriceAmount / 100)} each',
                style: const TextStyle(
                  fontSize: 12,
                  color: TavolaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(onPressed: onDecrease, child: const Text('−')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.sm),
          child: Text('${line.quantity}'),
        ),
        OutlinedButton(onPressed: onIncrease, child: const Text('+')),
        IconButton(
          onPressed: onRemove,
          color: TavolaColors.error,
          tooltip: 'Remove ${line.name}',
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}
