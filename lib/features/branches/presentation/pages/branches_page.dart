import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
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
            const TavolaPageHeader(
              title: 'Branches',
              subtitle: 'Manage restaurant locations and operating status',
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
