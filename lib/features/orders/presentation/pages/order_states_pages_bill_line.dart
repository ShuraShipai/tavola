part of 'order_states_pages.dart';

class _BillLine extends StatelessWidget {
  const _BillLine(this.name, this.value, {this.bold = false});
  final String name, value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
        Text(
          value,
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
        ),
      ],
    ),
  );
}
