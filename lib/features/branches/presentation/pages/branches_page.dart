import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/branch.dart';
import '../providers/branch_providers.dart';

class BranchesPage extends ConsumerWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(restaurantBranchesProvider);
    return TavolaAppShell(
      activeRoute: '/branches',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TavolaPageHeader(
              title: 'Branches',
              subtitle: 'Manage restaurant locations and operating status',
              actionLabel: 'Add branch',
              actionIcon: Icons.add,
              onAction: () => _showCreateBranch(context, ref),
            ),
            const SizedBox(height: TavolaSpace.lg),
            branches.when(
              loading: () => const SizedBox(
                height: 320,
                child: TavolaLoadingIndicator(label: 'Loading branches…'),
              ),
              error: (error, _) => SizedBox(
                height: 320,
                child: TavolaErrorState(
                  message: 'Unable to load branches.',
                  onRetry: () => ref.invalidate(restaurantBranchesProvider),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const SizedBox(
                      height: 320,
                      child: TavolaEmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No branches yet',
                        message:
                            'Your restaurant locations will appear here once they are configured.',
                      ),
                    )
                  : _BranchList(branches: items),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCreateBranch(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController(text: 'Main Branch');
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  try {
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add branch'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Branch name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a branch name'
                      : null,
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final membership = await ref.read(
                  currentMembershipProvider.future,
                );
                if (membership == null) {
                  throw StateError('Restaurant membership not found.');
                }
                await ref
                    .read(branchRepositoryProvider)
                    .saveBranch(
                      restaurantId: membership.restaurantId,
                      name: nameController.text,
                      address: addressController.text,
                      phone: phoneController.text,
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (created == true) ref.invalidate(restaurantBranchesProvider);
  } finally {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
  }
}

class _BranchList extends StatelessWidget {
  const _BranchList({required this.branches});
  final List<Branch> branches;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 900 ? 3 : 1,
            crossAxisSpacing: TavolaSpace.md,
            mainAxisSpacing: TavolaSpace.md,
            childAspectRatio: constraints.maxWidth > 900 ? 1.38 : 2,
          ),
          itemCount: branches.length,
          itemBuilder: (_, index) => _BranchCard(branch: branches[index]),
        ),
      ),
      const SizedBox(height: TavolaSpace.lg),
      const TavolaPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Branch details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: TavolaSpace.xs),
            Text(
              'Branch editing will be enabled in a future operations slice.',
            ),
          ],
        ),
      ),
    ],
  );
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch});
  final Branch branch;

  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: TavolaColors.accentLight,
              child: Icon(
                Icons.storefront_rounded,
                color: TavolaColors.accentDark,
              ),
            ),
            const Spacer(),
            TavolaStatusBadge(
              label: branch.isActive ? 'Active' : 'Inactive',
              color: branch.isActive
                  ? TavolaColors.success
                  : TavolaColors.textMuted,
            ),
          ],
        ),
        const Spacer(),
        Text(
          branch.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        const SizedBox(height: TavolaSpace.xxs),
        Text(
          branch.address ?? 'Address not configured',
          style: const TextStyle(
            color: TavolaColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: TavolaSpace.md),
        Text(
          branch.phone ?? 'Phone not configured',
          style: const TextStyle(color: TavolaColors.textSecondary),
        ),
        const SizedBox(height: TavolaSpace.xs),
        const OutlinedButton(onPressed: null, child: Text('View branch')),
      ],
    ),
  );
}
