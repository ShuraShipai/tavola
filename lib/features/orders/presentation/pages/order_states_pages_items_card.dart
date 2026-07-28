part of 'order_states_pages.dart';

class _ItemsCard extends StatelessWidget {
  const _ItemsCard();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        const _Item('Margherita Pizza', 'Extra cheese', '1', '₹340'),
        const _Item('Cold Coffee', 'No sugar', '2', '₹260'),
        const _Item('Paneer Tikka', '—', '1', '₹260'),
      ],
    ),
  );
}
