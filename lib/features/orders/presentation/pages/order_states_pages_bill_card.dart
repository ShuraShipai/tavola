part of 'order_states_pages.dart';

class _BillCard extends StatelessWidget {
  const _BillCard();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bill Summary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        const _BillLine('Subtotal', '₹860'),
        const _BillLine('Tax (5%)', '₹43'),
        const _BillLine('Service Charge', '₹43'),
        const Divider(),
        const _BillLine('Total', '₹946', bold: true),
      ],
    ),
  );
}
