part of 'order_states_pages.dart';

class _OrderListPage extends StatelessWidget {
  const _OrderListPage({required this.completed});
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final rows = completed
        ? const [
            [
              '#ORD-1039',
              'Table 9',
              '4 items',
              'Paid — UPI',
              '₹980',
              '1:52 PM',
            ],
            [
              '#ORD-1036',
              'Table 3',
              '6 items',
              'Paid — Card',
              '₹1,560',
              '1:15 PM',
            ],
            [
              '#ORD-1031',
              'Takeaway',
              '2 items',
              'Paid — Cash',
              '₹340',
              '12:40 PM',
            ],
          ]
        : const [
            [
              '#ORD-1042',
              'Table 5',
              '3 lines · 4 units',
              'Preparing',
              '₹946',
              '2:14 PM',
            ],
            [
              '#ORD-1041',
              'Table 2',
              '5 items',
              'Preparing',
              '₹1,240',
              '2:09 PM',
            ],
            ['#ORD-1040', 'Takeaway', '2 items', 'Ready', '₹260', '1:58 PM'],
            ['#ORD-1037', 'Table 7', '4 items', 'Placed', '₹720', '1:26 PM'],
          ];
    return TavolaAppShell(
      activeRoute: '/orders',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TavolaPageHeader(
              title: completed ? 'Completed Orders' : 'Active Orders',
              subtitle: completed
                  ? 'Orders served and paid today'
                  : 'Orders currently in progress across the restaurant',
              actionLabel: completed ? 'Export CSV' : 'New Order',
              actionIcon: completed ? Icons.download_outlined : Icons.add,
            ),
            const SizedBox(height: TavolaSpace.lg),
            TavolaPanel(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Order ID')),
                    DataColumn(label: Text('Table')),
                    DataColumn(label: Text('Items')),
                    DataColumn(label: Text('Payment / Status')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('')),
                  ],
                  rows: rows
                      .map(
                        (row) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                row[0],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...row
                                .sublist(1)
                                .map((cell) => DataCell(Text(cell))),
                            DataCell(
                              TextButton(
                                onPressed: () {},
                                child: Text(completed ? 'Receipt' : 'View'),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
