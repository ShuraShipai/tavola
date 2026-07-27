import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../domain/entities/restaurant_order.dart';

/// Presentation state for the active-order status filter.
enum OrderStatusFilter { all, placed, preparing, ready, held }

class OrderStatusFilterTabs extends StatelessWidget {
  const OrderStatusFilterTabs({
    required this.selected,
    required this.orders,
    required this.onSelected,
    super.key,
  });

  final OrderStatusFilter selected;
  final List<RestaurantOrder> orders;
  final ValueChanged<OrderStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: TavolaColors.border)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: OrderStatusFilter.values
            .map(
              (filter) => _FilterTab(
                label: '${_label(filter)} (${_count(filter)})',
                selected: selected == filter,
                onTap: () => onSelected(filter),
              ),
            )
            .toList(growable: false),
      ),
    ),
  );

  int _count(OrderStatusFilter filter) => filter == OrderStatusFilter.all
      ? orders.length
      : orders.where((order) => matchesOrderFilter(filter, order)).length;

  String _label(OrderStatusFilter filter) => switch (filter) {
    OrderStatusFilter.all => 'All',
    OrderStatusFilter.placed => 'Placed',
    OrderStatusFilter.preparing => 'Preparing',
    OrderStatusFilter.ready => 'Ready',
    OrderStatusFilter.held => 'Held',
  };
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TavolaSpace.xxs,
        vertical: TavolaSpace.sm,
      ),
      margin: const EdgeInsets.only(right: TavolaSpace.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? TavolaColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected
              ? TavolaColors.textPrimary
              : TavolaColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}

bool matchesOrderFilter(OrderStatusFilter filter, RestaurantOrder order) =>
    switch (filter) {
      OrderStatusFilter.all =>
        order.status != RestaurantOrderStatus.paid &&
            order.status != RestaurantOrderStatus.cancelled,
      OrderStatusFilter.placed =>
        order.status == RestaurantOrderStatus.open ||
            order.status == RestaurantOrderStatus.sentToKitchen,
      OrderStatusFilter.preparing =>
        order.status == RestaurantOrderStatus.preparing,
      OrderStatusFilter.ready =>
        order.status == RestaurantOrderStatus.ready ||
            order.status == RestaurantOrderStatus.served,
      OrderStatusFilter.held => order.status == RestaurantOrderStatus.draft,
    };
