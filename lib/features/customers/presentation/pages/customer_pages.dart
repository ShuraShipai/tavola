import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../../../core/validation/phone_validator.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_providers.dart';

class CustomersPage extends ConsumerWidget {
  const CustomersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(restaurantCustomersProvider);
    return _CustomerShell(
      title: 'Customers',
      subtitle: customers.when(
        data: (data) => '${data.length} customer profiles',
        loading: () => 'Loading customer profiles…',
        error: (_, _) => 'Unable to load customer profiles',
      ),
      action: 'Add Customer',
      child: customers.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(TavolaSpace.xl),
          child: TavolaLoadingIndicator(label: 'Loading customers…'),
        ),
        error: (error, _) => TavolaErrorState(
          message: 'We could not load your customer list.',
          onRetry: () => ref.invalidate(restaurantCustomersProvider),
        ),
        data: (data) => data.isEmpty
            ? const TavolaEmptyState(
                title: 'No customers yet',
                message: 'Customer profiles will appear here as you add them.',
                icon: Icons.people_outline,
              )
            : _CustomerDashboard(customers: data),
      ),
    );
  }
}

class _CustomerDashboard extends StatelessWidget {
  const _CustomerDashboard({required this.customers});
  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    final returning = customers
        .where((customer) => customer.visitCount > 1)
        .length;
    final newlyAdded = customers
        .where(
          (customer) => customer.createdAt.isAfter(
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        )
        .length;
    return Column(
      children: [
        LayoutBuilder(
          builder: (_, constraints) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth < 700 ? 2 : 4,
            childAspectRatio: 2.3,
            children: [
              TavolaMetricCard(
                label: 'Total customers',
                value: '${customers.length}',
                icon: Icons.people_outline,
                tone: Colors.amber,
                detail: '$newlyAdded joined this month',
              ),
              TavolaMetricCard(
                label: 'Returning guests',
                value: '${_percent(returning, customers.length)}%',
                icon: Icons.repeat,
                tone: Colors.green,
                detail: '$returning repeat guests',
              ),
              TavolaMetricCard(
                label: 'Total visits',
                value:
                    '${customers.fold<int>(0, (total, customer) => total + customer.visitCount)}',
                icon: Icons.restaurant_outlined,
                tone: Colors.blue,
                detail: 'Across all profiles',
              ),
              TavolaMetricCard(
                label: 'Customer notes',
                value:
                    '${customers.where((customer) => (customer.notes ?? '').isNotEmpty).length}',
                icon: Icons.notes_outlined,
                tone: Colors.orange,
                detail: 'Dietary and service notes',
              ),
            ],
          ),
        ),
        const SizedBox(height: TavolaSpace.lg),
        TavolaPanel(child: _LiveCustomerTable(customers: customers)),
      ],
    );
  }

  int _percent(int part, int total) =>
      total == 0 ? 0 : (part * 100 / total).round();
}

class _LiveCustomerTable extends StatelessWidget {
  const _LiveCustomerTable({required this.customers});
  final List<Customer> customers;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Visits')),
        DataColumn(label: Text('Joined')),
        DataColumn(label: Text('Notes')),
      ],
      rows: customers
          .map(
            (customer) => DataRow(
              cells: [
                DataCell(
                  Text(
                    customer.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(Text(customer.phone ?? '—')),
                DataCell(Text(customer.email ?? '—')),
                DataCell(Text('${customer.visitCount}')),
                DataCell(
                  Text(
                    '${customer.createdAt.day}/${customer.createdAt.month}/${customer.createdAt.year}',
                  ),
                ),
                DataCell(Text((customer.notes ?? '').isEmpty ? '—' : 'Yes')),
              ],
            ),
          )
          .toList(growable: false),
    ),
  );
}

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key, required this.customerId});
  final String customerId;
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
              .map(
                (x) => x == 'Phone number'
                    ? TextFormField(
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: x),
                        validator: validateIndianPhone,
                      )
                    : TextField(decoration: InputDecoration(labelText: x)),
              )
              .toList(),
    ),
  );
}
