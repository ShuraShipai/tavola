import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../../auth/domain/entities/restaurant_membership.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/dining_table.dart';
import '../providers/dining_table_providers.dart';

/// Screen 88 — create a service table in an active dining area.
class TableEditorPage extends ConsumerStatefulWidget {
  const TableEditorPage({this.tableId, super.key});

  final String? tableId;
  bool get isEdit => tableId != null;

  @override
  ConsumerState<TableEditorPage> createState() => _TableEditorPageState();
}

class _TableEditorPageState extends ConsumerState<TableEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _tableNumber = TextEditingController();
  final _capacity = TextEditingController();
  bool _saving = false;
  bool _initialised = false;
  String? _error;

  @override
  void dispose() {
    _tableNumber.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(currentMembershipProvider);
    final tables = ref.watch(restaurantTablesProvider);
    return TavolaAppShell(
      activeRoute: AppRoutes.tables,
      child: Padding(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: membership.when(
              loading: () =>
                  const TavolaLoadingIndicator(label: 'Loading table setup…'),
              error: (_, _) => TavolaErrorState(
                message: 'We could not load your restaurant access.',
                onRetry: () => ref.invalidate(currentMembershipProvider),
              ),
              data: (member) {
                if (member == null || !_canManage(member.role)) {
                  return const TavolaEmptyState(
                    title: 'Table setup is restricted',
                    message: 'Only owners and managers can add dining tables.',
                    icon: Icons.lock_outline,
                  );
                }
                if (!widget.isEdit) return _form(member.restaurantId);
                return tables.when(
                  loading: () =>
                      const TavolaLoadingIndicator(label: 'Loading table…'),
                  error: (_, _) => TavolaErrorState(
                    message: 'We could not load this table.',
                    onRetry: () => ref.invalidate(restaurantTablesProvider),
                  ),
                  data: (items) {
                    final table = items
                        .where((item) => item.id == widget.tableId)
                        .firstOrNull;
                    if (table == null) {
                      return const TavolaEmptyState(
                        title: 'Table not found',
                        message: 'It may already have been deleted.',
                        icon: Icons.table_restaurant_outlined,
                      );
                    }
                    return _form(member.restaurantId, table: table);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(String restaurantId, {DiningTable? table}) {
    if (!_initialised && table != null) {
      _initialised = true;
      _tableNumber.text = table.label.replaceFirst(
        RegExp(r'^Table\\s*', caseSensitive: false),
        '',
      );
      _capacity.text = table.capacity.toString();
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TavolaPageHeader(
            title: table == null ? 'New Table' : 'Edit ${table.label}',
            subtitle: table == null
                ? 'Add a table for service and reservations.'
                : 'Update this table’s setup. Service status updates live.',
          ),
          const SizedBox(height: TavolaSpace.lg),
          TavolaPanel(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _tableNumber,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Table number',
                      hintText: 'e.g. 1',
                    ),
                    validator: (value) {
                      final number = int.tryParse(value?.trim() ?? '');
                      return number == null || number < 1
                          ? 'Enter a table number, for example 1'
                          : null;
                    },
                  ),
                  const SizedBox(height: TavolaSpace.md),
                  TextFormField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of seats',
                      hintText: 'e.g. 4',
                    ),
                    validator: (value) {
                      final seats = int.tryParse(value ?? '');
                      return seats == null || seats < 1 || seats > 100
                          ? 'Enter 1–100 seats'
                          : null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: TavolaSpace.md),
                    Text(
                      _error!,
                      style: const TextStyle(color: TavolaColors.error),
                    ),
                  ],
                  const SizedBox(height: TavolaSpace.lg),
                  Row(
                    children: [
                      if (table != null)
                        TextButton(
                          onPressed: _saving ? null : () => _delete(table),
                          style: TextButton.styleFrom(
                            foregroundColor: TavolaColors.error,
                          ),
                          child: const Text('Delete Table'),
                        ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => context.go(AppRoutes.tables),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: TavolaSpace.sm),
                      FilledButton(
                        onPressed: _saving ? null : () => _save(restaurantId),
                        child: _saving
                            ? const SizedBox(
                                width: TavolaSize.iconMedium,
                                height: TavolaSize.iconMedium,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TavolaColors.textInverse,
                                ),
                              )
                            : Text(
                                table == null ? 'Save Table' : 'Save Changes',
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(String restaurantId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(createDiningTableProvider)(
        restaurantId: restaurantId,
        tableId: widget.tableId,
        label: 'Table ${_tableNumber.text.trim()}',
        capacity: int.parse(_capacity.text),
        sortOrder: int.parse(_tableNumber.text.trim()),
      );
      ref.invalidate(restaurantTablesProvider);
      if (mounted) context.go(AppRoutes.tables);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save this table. Check the table number and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(DiningTable table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${table.label}?'),
        content: const Text(
          'This is only allowed when the table has no active order, reservation, or merge.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Table'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TavolaColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Table'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(deleteDiningTableProvider)(table.id);
      ref.invalidate(restaurantTablesProvider);
      if (mounted) context.go(AppRoutes.tables);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'This table cannot be deleted while it is in service, reserved, or merged.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _canManage(TavolaRole role) =>
      role == TavolaRole.owner || role == TavolaRole.manager;
}
