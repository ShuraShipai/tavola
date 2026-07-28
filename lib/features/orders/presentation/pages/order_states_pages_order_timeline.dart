part of 'order_states_pages.dart';

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline();
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Row(
      children: const [
        Expanded(child: _Step('✓', 'Placed', '2:14 PM', true)),
        Expanded(child: _Step('🍳', 'Preparing', '2:16 PM', true)),
        Expanded(child: _Step('✓', 'Ready', '—', false)),
        Expanded(child: _Step('⌕', 'Served', '—', false)),
      ],
    ),
  );
}
