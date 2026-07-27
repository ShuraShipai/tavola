import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/discount_entities.dart';
import '../providers/discount_providers.dart';

/// Tenant-scoped discount and coupon catalogue; create/edit actions land in Phase 3.
class DiscountsPage extends ConsumerWidget {
  const DiscountsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => TavolaAppShell(
    activeRoute: '/discounts',
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: ref
          .watch(discountCatalogProvider)
          .when(
            loading: () =>
                const TavolaLoadingIndicator(label: 'Loading discounts…'),
            error: (error, _) => TavolaErrorState(
              message: 'Unable to load discounts.',
              onRetry: () => ref.invalidate(discountCatalogProvider),
            ),
            data: (catalog) => _DiscountContent(catalog: catalog),
          ),
    ),
  );
}

class _DiscountContent extends StatelessWidget {
  const _DiscountContent({required this.catalog});
  final DiscountCatalog catalog;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TavolaPageHeader(
          title: 'Discounts',
          subtitle: 'Create automatic and staff-applied offers',
          actionLabel: 'Create Discount',
        ),
        const SizedBox(height: TavolaSpace.lg),
        if (catalog.discounts.isEmpty)
          const TavolaEmptyState(
            title: 'No discounts yet',
            message: 'Create an offer to apply it to eligible bills.',
            icon: Icons.local_offer_outlined,
          )
        else
          LayoutBuilder(
            builder: (context, box) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: catalog.discounts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: box.maxWidth > 850 ? 3 : 1,
                crossAxisSpacing: TavolaSpace.md,
                mainAxisSpacing: TavolaSpace.md,
                childAspectRatio: box.maxWidth > 850 ? 1.55 : 2.2,
              ),
              itemBuilder: (context, index) =>
                  _DiscountCard(catalog.discounts[index]),
            ),
          ),
        const SizedBox(height: TavolaSpace.lg),
        TavolaPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(TavolaSpace.lg),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Coupon Codes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: null,
                      child: Text('Create Coupon'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (catalog.coupons.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: TavolaSpace.lg),
                  child: TavolaEmptyState(
                    title: 'No coupons yet',
                    message: 'Coupon codes will appear here once created.',
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Code')),
                      DataColumn(label: Text('Offer')),
                      DataColumn(label: Text('Redemptions')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: catalog.coupons
                        .map(
                          (coupon) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  coupon.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(Text(coupon.discountLabel)),
                              DataCell(
                                Text(
                                  coupon.redemptionLimit == null
                                      ? '${coupon.redemptionCount}'
                                      : '${coupon.redemptionCount} / ${coupon.redemptionLimit}',
                                ),
                              ),
                              DataCell(
                                TavolaStatusBadge(
                                  label: coupon.isActive
                                      ? 'Active'
                                      : 'Inactive',
                                  color: coupon.isActive
                                      ? TavolaColors.success
                                      : TavolaColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DiscountCard extends StatelessWidget {
  const _DiscountCard(this.discount);
  final Discount discount;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TavolaStatusBadge(
              label: discount.type == 'percentage'
                  ? '${discount.value}% off'
                  : '₹${discount.value / 100} off',
              color: TavolaColors.accentDark,
            ),
            const Spacer(),
            TavolaStatusBadge(
              label: discount.isActive ? 'Active' : 'Inactive',
              color: discount.isActive
                  ? TavolaColors.success
                  : TavolaColors.textMuted,
            ),
          ],
        ),
        const Spacer(),
        Text(
          discount.name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Usage',
              style: TextStyle(color: TavolaColors.textSecondary),
            ),
            const Spacer(),
            Text(
              '${discount.usageCount} times',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const OutlinedButton(onPressed: null, child: Text('Edit Discount')),
      ],
    ),
  );
}
