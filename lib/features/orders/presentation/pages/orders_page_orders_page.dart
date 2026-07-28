part of 'orders_page.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({this.initialTableId, super.key});

  final String? initialTableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(restaurantOrdersProvider);
    return TavolaAppShell(
      activeRoute: '/orders',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: orders.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(TavolaSpace.xl),
            child: TavolaLoadingIndicator(label: 'Loading orders…'),
          ),
          error: (error, _) => TavolaErrorState(
            message: 'We could not load your restaurant orders.',
            onRetry: () => ref.invalidate(restaurantOrdersProvider),
          ),
          data: (data) =>
              _OrdersWorkspace(orders: data, initialTableId: initialTableId),
        ),
      ),
    );
  }
}
