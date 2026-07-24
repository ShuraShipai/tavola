import 'package:flutter/material.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

/// Static multi-branch overview and branch-editor state for future locations.
class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key});
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/branches',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'Branches',
            subtitle: 'Manage restaurant locations and operating status',
            actionLabel: 'Add Branch',
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, c) => GridView.count(
              crossAxisCount: c.maxWidth > 900 ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: TavolaSpace.md,
              mainAxisSpacing: TavolaSpace.md,
              childAspectRatio: c.maxWidth > 900 ? 1.38 : 2,
              children: const [
                _Branch(
                  'La Rosetta Café',
                  'Park Street · New Delhi',
                  'Open now',
                  '₹48,250',
                  '186 orders',
                  TavolaColors.success,
                ),
                _Branch(
                  'La Rosetta North',
                  'Civil Lines · New Delhi',
                  'Open now',
                  '₹36,840',
                  '142 orders',
                  TavolaColors.success,
                ),
                _Branch(
                  'La Rosetta Airport',
                  'Terminal 3 · New Delhi',
                  'Closed',
                  '₹0',
                  'Opens 6:00 AM',
                  TavolaColors.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: TavolaSpace.lg),
          TavolaPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Branch details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TavolaSpace.md),
                const Wrap(
                  spacing: TavolaSpace.md,
                  runSpacing: TavolaSpace.md,
                  children: [
                    _BranchInput('Branch name', 'La Rosetta Café'),
                    _BranchInput('Phone', '+91 98100 44218'),
                    _BranchInput('Address', '12 Park Street, New Delhi'),
                    _BranchInput('GSTIN', '07AAACL1234A1Z5'),
                    _BranchInput('Opening hours', '10:00 AM – 11:00 PM'),
                    _BranchInput('Default tax', 'GST 5%'),
                  ],
                ),
                const SizedBox(height: TavolaSpace.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Save Branch'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Branch extends StatelessWidget {
  const _Branch(
    this.name,
    this.address,
    this.status,
    this.sales,
    this.orders,
    this.color,
  );
  final String name, address, status, sales, orders;
  final Color color;
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
            TavolaStatusBadge(label: status, color: color),
          ],
        ),
        const Spacer(),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        const SizedBox(height: 4),
        Text(
          address,
          style: const TextStyle(
            color: TavolaColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              sales,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              orders,
              style: const TextStyle(color: TavolaColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () {}, child: const Text('View branch')),
      ],
    ),
  );
}

class _BranchInput extends StatelessWidget {
  const _BranchInput(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 250,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(decoration: InputDecoration(hintText: value)),
      ],
    ),
  );
}
