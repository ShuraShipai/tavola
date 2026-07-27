import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/staff_member.dart';
import '../providers/staff_providers.dart';

class StaffPage extends ConsumerWidget {
  const StaffPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(restaurantStaffProvider);
    return _StaffShell(
      title: 'Staff',
      subtitle: 'Manage team access, roles and current shift status',
      child: staff.when(
        loading: () => const SizedBox(
          height: 320,
          child: TavolaLoadingIndicator(label: 'Loading staff…'),
        ),
        error: (error, _) => SizedBox(
          height: 320,
          child: TavolaErrorState(
            message: 'Unable to load staff.',
            onRetry: () => ref.invalidate(restaurantStaffProvider),
          ),
        ),
        data: (members) => members.isEmpty
            ? const SizedBox(
                height: 320,
                child: TavolaEmptyState(
                  icon: Icons.badge_outlined,
                  title: 'No staff members yet',
                  message:
                      'Staff will appear here after a secure invitation workflow is added.',
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TavolaPanel(child: _StaffMemberTable(members: members)),
                  const SizedBox(height: TavolaSpace.md),
                  const Text(
                    'Staff invitations are not available yet. They require a secure server-side workflow.',
                  ),
                ],
              ),
      ),
    );
  }
}

class _StaffMemberTable extends StatelessWidget {
  const _StaffMemberTable({required this.members});
  final List<StaffMember> members;

  @override
  Widget build(BuildContext context) => _StaffTable(
    headers: const ['Staff member', 'Role', 'Contact', 'Status'],
    rows: members
        .map(
          (member) => [
            member.fullName?.trim().isNotEmpty == true
                ? member.fullName!
                : 'Unnamed staff member',
            member.role.label,
            member.email ?? 'No email',
            member.isActive ? 'Active' : 'Inactive',
          ],
        )
        .toList(growable: false),
    onRowSelected: (index) => context.go('/staff/edit/${members[index].id}'),
  );
}

class AddStaffPage extends StatelessWidget {
  const AddStaffPage({super.key});
  @override
  Widget build(BuildContext context) => _StaffShell(
    title: 'Add Staff Member',
    subtitle: 'Create a staff account and assign access',
    child: TavolaPanel(
      child: Column(
        children: [
          const _StaffFields(),
          const SizedBox(height: TavolaSpace.md),
          const Text(
            'Staff invitations will be enabled after a secure server-side invitation workflow is available.',
          ),
          const SizedBox(height: TavolaSpace.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: null,
              child: const Text('Add Staff Member'),
            ),
          ),
        ],
      ),
    ),
  );
}

class EditStaffPage extends ConsumerWidget {
  const EditStaffPage({this.membershipId, super.key});
  final String? membershipId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref
        .watch(restaurantStaffProvider)
        .asData
        ?.value
        .where((item) => item.id == membershipId)
        .firstOrNull;
    return _StaffEditor(
      title: 'Edit Staff',
      subtitle: member == null
          ? 'Select a staff member from the Staff list.'
          : '${member.fullName ?? 'Staff member'} · ${member.role.label}',
      button: 'Save Changes',
      member: member,
    );
  }
}

class _StaffEditor extends StatelessWidget {
  const _StaffEditor({
    required this.title,
    required this.subtitle,
    required this.button,
    this.member,
  });
  final String title, subtitle, button;
  final StaffMember? member;
  @override
  Widget build(BuildContext context) => _StaffShell(
    title: title,
    subtitle: subtitle,
    child: TavolaPanel(
      child: Column(
        children: [
          const _StaffFields(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (member != null)
                OutlinedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _SetStaffPinDialog(member: member!),
                  ),
                  child: const Text('Reset Staff PIN'),
                ),
              const SizedBox(width: TavolaSpace.sm),
              FilledButton(onPressed: () {}, child: Text(button)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SetStaffPinDialog extends ConsumerStatefulWidget {
  const _SetStaffPinDialog({required this.member});
  final StaffMember member;

  @override
  ConsumerState<_SetStaffPinDialog> createState() => _SetStaffPinDialogState();
}

class _SetStaffPinDialogState extends ConsumerState<_SetStaffPinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Reset PIN for ${widget.member.fullName ?? 'staff member'}'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'The previous PIN will stop working immediately after reset.',
          ),
          const SizedBox(height: TavolaSpace.md),
          TextFormField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'New 4-digit PIN'),
            validator: (value) =>
                value == null || !RegExp(r'^\d{4}$').hasMatch(value)
                ? 'Enter exactly four digits.'
                : null,
          ),
          TextFormField(
            controller: _confirm,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'Confirm new PIN'),
            validator: (value) =>
                value != _pin.text ? 'PINs do not match.' : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Reset PIN')),
    ],
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .setStaffPin(membershipId: widget.member.id, pin: _pin.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff PIN reset successfully.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to reset the staff PIN.')),
        );
      }
    }
  }
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
  const _StaffTable({
    required this.headers,
    required this.rows,
    this.onRowSelected,
  });
  final List<String> headers;
  final List<List<String>> rows;
  final ValueChanged<int>? onRowSelected;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: headers.map((x) => DataColumn(label: Text(x))).toList(),
      rows: rows
          .asMap()
          .entries
          .map(
            (entry) => DataRow(
              onSelectChanged: onRowSelected == null
                  ? null
                  : (_) => onRowSelected!(entry.key),
              cells: entry.value.map((x) => DataCell(Text(x))).toList(),
            ),
          )
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
