import 'package:flutter/material.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class StaffPage extends StatelessWidget {
  const StaffPage({super.key});
  @override
  Widget build(BuildContext context) => _StaffShell(
    title: 'Staff',
    subtitle: 'Manage team access, roles and current shift status',
    action: 'Add Staff',
    child: const TavolaPanel(
      child: _StaffTable(
        headers: ['Staff member', 'Role', 'Contact', 'Shift status'],
        rows: [
          ['Rahul Sharma', 'Administrator', 'rahul@larosetta.in', 'On shift'],
          ['Anita Nair', 'Waiter', '+91 98210 46320', 'On shift'],
          ['Kabir Singh', 'Chef', '+91 98911 30082', 'Off shift'],
          ['Meera Das', 'Cashier', 'meera@larosetta.in', 'Break'],
        ],
      ),
    ),
  );
}

class AddStaffPage extends StatelessWidget {
  const AddStaffPage({super.key});
  @override
  Widget build(BuildContext context) => const _StaffEditor(
    title: 'Add Staff Member',
    subtitle: 'Create a staff account and assign access',
    button: 'Add Staff Member',
  );
}

class EditStaffPage extends StatelessWidget {
  const EditStaffPage({super.key});
  @override
  Widget build(BuildContext context) => const _StaffEditor(
    title: 'Edit Staff',
    subtitle: 'Anita Nair · EMP-018 · Joined 7 Jan 2025',
    button: 'Save Changes',
  );
}

class _StaffEditor extends StatelessWidget {
  const _StaffEditor({
    required this.title,
    required this.subtitle,
    required this.button,
  });
  final String title, subtitle, button;
  @override
  Widget build(BuildContext context) => _StaffShell(
    title: title,
    subtitle: subtitle,
    child: TavolaPanel(
      child: Column(
        children: [
          const _StaffFields(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: () {}, child: Text(button)),
          ),
        ],
      ),
    ),
  );
}

class RolesPermissionsPage extends StatelessWidget {
  const RolesPermissionsPage({super.key});
  @override
  Widget build(BuildContext context) => _StaffShell(
    title: 'Roles & Permissions',
    subtitle: 'Control what each staff role can view and change',
    action: 'Create Role',
    child: const TavolaPanel(
      child: _StaffTable(
        headers: ['Module', 'View', 'Create', 'Edit', 'Delete'],
        rows: [
          ['Orders', '●', '●', '●', '○'],
          ['Tables', '●', '●', '●', '○'],
          ['Billing', '●', '○', '○', '○'],
          ['Customers', '●', '●', '○', '○'],
          ['Reports', '○', '○', '○', '○'],
        ],
      ),
    ),
  );
}

class CreateRolePage extends StatelessWidget {
  const CreateRolePage({super.key});
  @override
  Widget build(BuildContext context) => _StaffShell(
    title: 'Create Role',
    subtitle: 'Define a reusable access level for staff',
    child: TavolaPanel(
      child: Column(
        children: [
          const _StaffFields(),
          const SizedBox(height: 16),
          FilledButton(onPressed: () {}, child: const Text('Create Role')),
        ],
      ),
    ),
  );
}

class _StaffShell extends StatelessWidget {
  const _StaffShell({
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
    activeRoute: '/staff',
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

class _StaffTable extends StatelessWidget {
  const _StaffTable({required this.headers, required this.rows});
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

class _StaffFields extends StatelessWidget {
  const _StaffFields();
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
                'Phone',
                'Email',
                'Role',
                'Employee ID',
                '4-digit staff PIN',
              ]
              .map((x) => TextField(decoration: InputDecoration(labelText: x)))
              .toList(),
    ),
  );
}
