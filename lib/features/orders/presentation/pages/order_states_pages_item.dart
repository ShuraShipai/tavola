part of 'order_states_pages.dart';

class _Item extends StatelessWidget {
  const _Item(this.name, this.note, this.qty, this.total);
  final String name, note, qty, total;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TavolaSpace.sm),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 12,
                  color: TavolaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(qty),
        const SizedBox(width: 40),
        Text(total, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
