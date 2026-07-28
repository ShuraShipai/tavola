part of 'order_states_pages.dart';

class _OrderSummary extends StatelessWidget {
  const _OrderSummary();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => box.maxWidth > 720
        ? const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _ItemsCard()),
              SizedBox(width: TavolaSpace.md),
              Expanded(child: _BillCard()),
            ],
          )
        : const Column(
            children: [
              _ItemsCard(),
              SizedBox(height: TavolaSpace.md),
              _BillCard(),
            ],
          ),
  );
}
