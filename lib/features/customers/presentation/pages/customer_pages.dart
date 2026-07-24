import 'package:flutter/material.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});
  @override
  Widget build(BuildContext context) => _CustomerShell(
    title: 'Customers',
    subtitle: '1,248 customer profiles · 86 joined this month',
    action: 'Add Customer',
    child: Column(
      children: [
        LayoutBuilder(
          builder: (_, c) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: c.maxWidth < 700 ? 2 : 4,
            childAspectRatio: 2.3,
            children: const [
              TavolaMetricCard(
                label: 'Total customers',
                value: '1,248',
                icon: Icons.people_outline,
                tone: Colors.amber,
                detail: '▲ 7.4% this month',
              ),
              TavolaMetricCard(
                label: 'Returning guests',
                value: '68%',
                icon: Icons.repeat,
                tone: Colors.green,
                detail: '▲ 3.1%',
              ),
              TavolaMetricCard(
                label: 'Loyalty members',
                value: '742',
                icon: Icons.stars_outlined,
                tone: Colors.blue,
                detail: '59% of customers',
              ),
              TavolaMetricCard(
                label: 'Avg. lifetime spend',
                value: '₹8.4k',
                icon: Icons.payments_outlined,
                tone: Colors.orange,
                detail: '▲ ₹620',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const TavolaPanel(
          child: _CustomerTable(
            headers: [
              'Customer',
              'Phone',
              'Visits',
              'Last visit',
              'Total spent',
              'Loyalty',
            ],
            rows: [
              [
                'Arjun Mehta',
                '+91 98765 43210',
                '18',
                'Today',
                '₹12,460',
                'Gold',
              ],
              [
                'Sana Kapoor',
                '+91 98111 28420',
                '11',
                '18 Jul',
                '₹8,920',
                'Silver',
              ],
              [
                'Dev Malhotra',
                '+91 98920 33441',
                '4',
                '15 Jul',
                '₹3,180',
                'Member',
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});
  @override
  Widget build(BuildContext context) => _CustomerShell(
    title: 'Customer Profile',
    subtitle: 'Guest history, preferences and loyalty activity',
    action: 'Edit Profile',
    child: Column(
      children: [
        const TavolaPanel(
          child: ListTile(
            leading: CircleAvatar(radius: 28, child: Text('AM')),
            title: Text(
              'Arjun Mehta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            subtitle: Text('Gold member · Customer since March 2025'),
            trailing: Text('1,240\nLoyalty points', textAlign: TextAlign.right),
          ),
        ),
        const SizedBox(height: 16),
        const TavolaPanel(
          child: _CustomerTable(
            headers: ['Date', 'Invoice', 'Guests', 'Amount', 'Points'],
            rows: [
              ['19 Jul 2026', '#INV-2048', '4', '₹891', '+89'],
              ['02 Jul 2026', '#INV-1884', '2', '₹1,240', '+124'],
            ],
          ),
        ),
      ],
    ),
  );
}

class AddCustomerPage extends StatelessWidget {
  const AddCustomerPage({super.key});
  @override
  Widget build(BuildContext context) => const _CustomerForm(
    title: 'Add Customer',
    subtitle: 'Create a profile for faster billing and loyalty rewards',
    button: 'Add Customer',
  );
}

class EditCustomerPage extends StatelessWidget {
  const EditCustomerPage({super.key});
  @override
  Widget build(BuildContext context) => const _CustomerForm(
    title: 'Edit Customer',
    subtitle: 'Arjun Mehta · ID CUS-01042',
    button: 'Save Changes',
  );
}

class _CustomerForm extends StatelessWidget {
  const _CustomerForm({
    required this.title,
    required this.subtitle,
    required this.button,
  });
  final String title, subtitle, button;
  @override
  Widget build(BuildContext context) => _CustomerShell(
    title: title,
    subtitle: subtitle,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: TavolaPanel(
        child: Column(
          children: [
            const _CustomerFields(),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Dietary notes',
                hintText: 'Allergies, preferences or seating notes',
              ),
            ),
            const CheckboxListTile(
              value: true,
              onChanged: null,
              contentPadding: EdgeInsets.zero,
              title: Text('Enrol customer in Tavola Rewards'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: () {}, child: Text(button)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CustomerShell extends StatelessWidget {
  const _CustomerShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });
  final String title, subtitle;
  final Widget child;
  final String? action;
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/customers',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TavolaPageHeader(
            title: title,
            subtitle: subtitle,
            actionLabel: action,
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    ),
  );
}

class _CustomerTable extends StatelessWidget {
  const _CustomerTable({required this.headers, required this.rows});
  final List<String> headers;
  final List<List<String>> rows;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: headers.map((x) => DataColumn(label: Text(x))).toList(),
      rows: rows
          .map((r) => DataRow(cells: r.map((x) => DataCell(Text(x))).toList()))
          .toList(),
    ),
  );
}

class _CustomerFields extends StatelessWidget {
  const _CustomerFields();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) => GridView.count(
      crossAxisCount: c.maxWidth < 500 ? 1 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 3.2,
      children:
          [
                'First name',
                'Last name',
                'Phone number',
                'Email address',
                'Date of birth',
                'Anniversary',
              ]
              .map((x) => TextField(decoration: InputDecoration(labelText: x)))
              .toList(),
    ),
  );
}
