import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/app_routes.dart';
import '../core/widgets/tavola_feature_page.dart';
import '../features/auth/presentation/pages/auth_pages.dart';
import '../features/auth/domain/entities/restaurant_membership.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/billing/presentation/pages/billing_page.dart';
import '../features/billing/presentation/pages/billing_state_pages.dart';
import '../features/branches/presentation/pages/branches_page.dart';
import '../features/customers/presentation/pages/customer_pages.dart';
import '../features/discounts/presentation/pages/discounts_page.dart';
import '../features/inventory/presentation/pages/inventory_page.dart';
import '../features/kitchen/presentation/pages/kitchen_page.dart';
import '../features/kitchen/presentation/pages/kitchen_state_pages.dart';
import '../features/menu/presentation/pages/menu_page.dart';
import '../features/orders/presentation/pages/orders_page.dart';
import '../features/orders/presentation/pages/order_states_pages.dart';
import '../features/reports/presentation/pages/reports_page.dart';
import '../features/reservations/presentation/pages/reservations_page.dart';
import '../features/settings/presentation/pages/settings_pages.dart';
import '../features/staff/presentation/pages/staff_pages.dart';
import '../features/support/presentation/pages/support_page.dart';
import '../features/tables/presentation/pages/tables_page.dart';
import '../features/tables/presentation/pages/table_states_pages.dart';

final _routerRefreshProvider = Provider<_RouterRefresh>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return refresh;
});

final tavolaRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authUserProvider);
      final membership = ref.read(currentMembershipProvider);
      final location = state.matchedLocation;
      const authRoutes = {
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.forgotPassword,
        AppRoutes.registerRestaurant,
        AppRoutes.joinRestaurant,
        AppRoutes.staffPin,
      };
      final isAuthRoute = authRoutes.contains(location);

      if (auth.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (auth.dataOrNull == null) {
        return isAuthRoute && location != AppRoutes.splash
            ? null
            : AppRoutes.welcome;
      }
      if (membership.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (membership.dataOrNull == null) {
        return location == AppRoutes.registerRestaurant
            ? null
            : AppRoutes.registerRestaurant;
      }
      if (isAuthRoute) return AppRoutes.dashboard;
      if (!_canAccess(membership.dataOrNull!.role, location)) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRouteName.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.orders,
        name: AppRouteName.orders,
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: AppRoutes.tables,
        name: AppRouteName.tables,
        builder: (context, state) => const TablesPage(),
      ),
      GoRoute(
        path: AppRoutes.kitchen,
        name: AppRouteName.kitchen,
        builder: (context, state) => const KitchenPage(),
      ),
      GoRoute(
        path: AppRoutes.billing,
        name: AppRouteName.billing,
        builder: (context, state) => const BillingPage(),
      ),
      GoRoute(
        path: AppRoutes.menu,
        name: AppRouteName.menu,
        builder: (context, state) => const MenuPage(),
      ),
      GoRoute(
        path: AppRoutes.customers,
        name: AppRouteName.customers,
        builder: (context, state) => const CustomersPage(),
      ),
      GoRoute(
        path: AppRoutes.staff,
        name: AppRouteName.staff,
        builder: (context, state) => const StaffPage(),
      ),
      GoRoute(
        path: AppRoutes.discounts,
        name: AppRouteName.discounts,
        builder: (context, state) => const DiscountsPage(),
      ),
      GoRoute(
        path: AppRoutes.inventory,
        name: AppRouteName.inventory,
        builder: (context, state) => const InventoryPage(),
      ),
      GoRoute(
        path: AppRoutes.reservations,
        name: AppRouteName.reservations,
        builder: (context, state) => const ReservationsPage(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        name: AppRouteName.reports,
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: AppRoutes.branches,
        name: AppRouteName.branches,
        builder: (context, state) => const BranchesPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRouteName.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportPage(),
      ),
      GoRoute(
        path: '/auth/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/auth/register-restaurant',
        name: 'register-restaurant',
        builder: (context, state) => const RegisterRestaurantPage(),
      ),
      GoRoute(
        path: '/auth/join-restaurant',
        name: 'join-restaurant',
        builder: (context, state) => const JoinRestaurantPage(),
      ),
      GoRoute(
        path: '/auth/staff-pin',
        name: 'staff-pin',
        builder: (context, state) => const StaffPinLoginPage(),
      ),
      GoRoute(
        path: '/orders/active',
        name: 'active-orders',
        builder: (context, state) => const ActiveOrdersPage(),
      ),
      GoRoute(
        path: '/orders/completed',
        name: 'completed-orders',
        builder: (context, state) => const CompletedOrdersPage(),
      ),
      GoRoute(
        path: '/orders/detail',
        name: 'order-detail',
        builder: (context, state) => const OrderDetailPage(),
      ),
      GoRoute(
        path: '/orders/edit',
        name: 'edit-order',
        builder: (context, state) => const EditOrderPage(),
      ),
      GoRoute(
        path: '/tables/detail',
        name: 'table-detail',
        builder: (context, state) => const TableDetailPage(),
      ),
      GoRoute(
        path: '/tables/merge',
        name: 'merge-tables',
        builder: (context, state) => const MergeTablesPage(),
      ),
      GoRoute(
        path: '/tables/split',
        name: 'split-tables',
        builder: (context, state) => const SplitTablePage(),
      ),
      GoRoute(
        path: '/kitchen/detail',
        name: 'kitchen-detail',
        builder: (context, state) => const KitchenOrderDetailPage(),
      ),
      GoRoute(
        path: '/kitchen/ticket-preview',
        name: 'ticket-preview',
        builder: (context, state) => const KitchenTicketPreviewPage(),
      ),
      GoRoute(
        path: '/billing/split',
        name: 'split-bill',
        builder: (context, state) => const SplitBillPage(),
      ),
      GoRoute(
        path: '/billing/payment',
        name: 'payment',
        builder: (context, state) => const PaymentPage(),
      ),
      GoRoute(
        path: '/billing/receipt',
        name: 'receipt',
        builder: (context, state) => const ReceiptPage(),
      ),
      GoRoute(
        path: '/billing/preview',
        name: 'bill-preview',
        builder: (context, state) => const BillPreviewPage(),
      ),
      GoRoute(
        path: '/billing/reprint',
        name: 'reprint-receipt',
        builder: (context, state) => const ReprintReceiptPage(),
      ),
      GoRoute(
        path: '/billing/refund',
        name: 'refund-void',
        builder: (context, state) => const RefundVoidPage(),
      ),
      GoRoute(
        path: '/customers/profile',
        name: 'customer-profile',
        builder: (context, state) => const CustomerProfilePage(),
      ),
      GoRoute(
        path: '/customers/add',
        name: 'add-customer',
        builder: (context, state) => const AddCustomerPage(),
      ),
      GoRoute(
        path: '/customers/edit',
        name: 'edit-customer',
        builder: (context, state) => const EditCustomerPage(),
      ),
      GoRoute(
        path: '/staff/add',
        name: 'add-staff',
        builder: (context, state) => const AddStaffPage(),
      ),
      GoRoute(
        path: '/staff/edit',
        name: 'edit-staff',
        builder: (context, state) => const EditStaffPage(),
      ),
      GoRoute(
        path: '/staff/roles',
        name: 'roles',
        builder: (context, state) => const RolesPermissionsPage(),
      ),
      GoRoute(
        path: '/staff/create-role',
        name: 'create-role',
        builder: (context, state) => const CreateRolePage(),
      ),
      GoRoute(
        path: '/settings/restaurant',
        name: 'restaurant-profile',
        builder: (context, state) => const RestaurantProfilePage(),
      ),
      GoRoute(
        path: '/settings/billing-tax',
        name: 'billing-tax',
        builder: (context, state) => const BillingTaxSettingsPage(),
      ),
      GoRoute(
        path: '/settings/payments',
        name: 'payment-methods',
        builder: (context, state) => const PaymentMethodsPage(),
      ),
      GoRoute(
        path: '/settings/app',
        name: 'app-settings',
        builder: (context, state) => const AppSettingsPage(),
      ),
      GoRoute(
        path: '/settings/profile',
        name: 'my-profile',
        builder: (context, state) => const MyProfilePage(),
      ),
      GoRoute(
        path: '/settings/password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/settings/help',
        name: 'help-support',
        builder: (context, state) => const HelpSupportPage(),
      ),
      ..._featureRoutes,
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(
      authUserProvider,
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
    _ref.listen(
      currentMembershipProvider,
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
}

bool _canAccess(TavolaRole role, String location) {
  if (role == TavolaRole.owner || role == TavolaRole.manager) return true;
  const cashierBlocked = {
    AppRoutes.staff,
    AppRoutes.branches,
    AppRoutes.inventory,
    AppRoutes.settings,
  };
  const waiterAllowed = {
    AppRoutes.dashboard,
    AppRoutes.orders,
    AppRoutes.tables,
    AppRoutes.kitchen,
    AppRoutes.customers,
    AppRoutes.reservations,
  };
  const kitchenAllowed = {AppRoutes.dashboard, AppRoutes.kitchen};
  return switch (role) {
    TavolaRole.cashier => !cashierBlocked.contains(location),
    TavolaRole.waiter => waiterAllowed.contains(location),
    TavolaRole.kitchen => kitchenAllowed.contains(location),
    TavolaRole.owner || TavolaRole.manager => true,
  };
}

final _featureRoutes = _featureConfigs
    .where(
      (config) =>
          config.route != AppRoutes.orders &&
          config.route != AppRoutes.tables &&
          config.route != AppRoutes.kitchen &&
          config.route != AppRoutes.billing &&
          config.route != AppRoutes.menu &&
          config.route != AppRoutes.customers &&
          config.route != AppRoutes.staff &&
          config.route != AppRoutes.discounts &&
          config.route != AppRoutes.inventory &&
          config.route != AppRoutes.reservations &&
          config.route != AppRoutes.reports &&
          config.route != AppRoutes.branches &&
          config.route != AppRoutes.settings,
    )
    .map(
      (config) => GoRoute(
        path: config.route,
        name: config.route.substring(1),
        builder: (context, state) => TavolaFeaturePage(config: config),
      ),
    )
    .toList();

const _featureConfigs = [
  TavolaFeatureConfig(
    route: AppRoutes.orders,
    title: 'Active Orders',
    subtitle: 'Track dine-in, takeaway, and delivery orders.',
    actionLabel: 'New Order',
    icon: Icons.add_rounded,
    summaryLabels: ['Active orders', 'Preparing', 'Ready to serve'],
    columns: ['Order', 'Type', 'Table / Customer', 'Status', 'Amount', 'Time'],
    rows: [
      ['#ORD-1042', 'Dine-in', 'Table 5', 'Preparing', '₹946', '2:14 PM'],
      ['#ORD-1041', 'Dine-in', 'Table 2', 'Preparing', '₹1,240', '2:09 PM'],
      ['#ORD-1040', 'Takeaway', 'Anita Nair', 'Ready', '₹260', '1:58 PM'],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.tables,
    title: 'Table Overview',
    subtitle: 'Monitor every dining area and table status.',
    actionLabel: 'Manage Tables',
    icon: Icons.table_restaurant_outlined,
    summaryLabels: [
      'Available tables',
      'Occupied tables',
      'Reservations today',
    ],
    columns: ['Table', 'Area', 'Capacity', 'Status', 'Order', 'Guests'],
    rows: [
      ['Table 5', 'Main Dining', '4 seats', 'Occupied', '#ORD-1042', '3'],
      ['Table 2', 'Main Dining', '2 seats', 'Occupied', '#ORD-1041', '2'],
      ['Table 12', 'Terrace', '6 seats', 'Available', '—', '—'],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.kitchen,
    title: 'Kitchen Display',
    subtitle: 'Keep preparation tickets visible to the kitchen team.',
    actionLabel: 'Kitchen Settings',
    icon: Icons.soup_kitchen_outlined,
    summaryLabels: ['New tickets', 'Preparing', 'Ready for service'],
    columns: ['Ticket', 'Order', 'Station', 'Items', 'Status', 'Elapsed'],
    rows: [
      [
        'KOT-3194',
        '#ORD-1042',
        'Main Kitchen',
        '4 items',
        'Preparing',
        '08 min',
      ],
      [
        'KOT-3193',
        '#ORD-1041',
        'Main Kitchen',
        '3 items',
        'Preparing',
        '13 min',
      ],
      ['KOT-3192', '#ORD-1040', 'Beverage', '2 items', 'Ready', '16 min'],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.billing,
    title: 'Billing & Payments',
    subtitle: 'Review bills, payment records, and outstanding balances.',
    actionLabel: 'Create Bill',
    icon: Icons.payments_outlined,
    summaryLabels: ['Paid today', 'Unpaid bills', 'Refunds'],
    columns: ['Invoice', 'Order', 'Customer', 'Payment', 'Total', 'Status'],
    rows: [
      ['INV-2052', '#ORD-1042', 'Table 5', 'UPI', '₹946', 'Paid'],
      ['INV-2051', '#ORD-1041', 'Table 2', 'Card', '₹1,240', 'Pending'],
      ['INV-2050', '#ORD-1037', 'Rhea Kapoor', 'Cash', '₹1,680', 'Unpaid'],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.menu,
    title: 'Menu Items',
    subtitle: 'Manage categories, prices, availability, and modifiers.',
    actionLabel: 'Add Menu Item',
    icon: Icons.restaurant_menu_outlined,
    summaryLabels: ['Menu items', 'Available now', 'Categories'],
    columns: ['Item', 'Category', 'Type', 'Price', 'Availability', 'Updated'],
    rows: [
      ['Margherita Pizza', 'Main Course', 'Veg', '₹340', 'Available', 'Today'],
      [
        'Butter Chicken',
        'Main Course',
        'Non-veg',
        '₹380',
        'Available',
        'Today',
      ],
      ['Tiramisu', 'Desserts', 'Veg', '₹220', 'Unavailable', 'Yesterday'],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.customers,
    title: 'Customers',
    subtitle: 'View guest profiles, visits, preferences, and loyalty activity.',
    actionLabel: 'Add Customer',
    icon: Icons.person_add_alt_1_outlined,
    summaryLabels: ['Customers', 'Returning guests', 'New this month'],
    columns: [
      'Customer',
      'Phone',
      'Visits',
      'Total spent',
      'Last visit',
      'Status',
    ],
    rows: [
      ['Anita Nair', '+91 98765 43210', '14', '₹18,240', 'Today', 'Active'],
      ['Rhea Kapoor', '+91 98765 43029', '9', '₹12,680', 'Yesterday', 'Active'],
      ['Vikram Shah', '+91 98765 43277', '3', '₹3,420', '15 Jul', 'Active'],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.staff,
    title: 'Staff & Permissions',
    subtitle: 'Organize roles, PIN access, and team permissions.',
    actionLabel: 'Add Staff',
    icon: Icons.badge_outlined,
    summaryLabels: ['Team members', 'On shift', 'Roles'],
    columns: [
      'Staff member',
      'Role',
      'PIN access',
      'Status',
      'Last active',
      'Branch',
    ],
    rows: [
      ['Rahul Sharma', 'Owner', 'Enabled', 'Active', 'Now', 'Main'],
      ['Meera Das', 'Manager', 'Enabled', 'Active', 'Now', 'Main'],
      ['Arjun Mehta', 'Waiter', 'Enabled', 'Off shift', 'Yesterday', 'Main'],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.discounts,
    title: 'Discounts & Coupons',
    subtitle: 'Manage offers that apply to eligible orders and guests.',
    actionLabel: 'Create Discount',
    icon: Icons.local_offer_outlined,
    summaryLabels: ['Active discounts', 'Redemptions today', 'Savings today'],
    columns: ['Offer', 'Type', 'Value', 'Validity', 'Redemptions', 'Status'],
    rows: [
      ['Weekday Lunch', 'Bill discount', '10%', 'Mon–Fri', '28', 'Active'],
      ['WELCOME20', 'Coupon', '20%', 'Until 31 Dec', '184', 'Active'],
      ['Happy Hour', 'Item discount', '15%', '4–6 PM', '12', 'Scheduled'],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.inventory,
    title: 'Inventory',
    subtitle: 'Keep stock levels and purchase requirements visible.',
    actionLabel: 'Add Stock Item',
    icon: Icons.inventory_2_outlined,
    summaryLabels: ['Stock items', 'Low stock', 'Purchase value'],
    columns: [
      'Item',
      'Category',
      'On hand',
      'Reorder level',
      'Supplier',
      'Status',
    ],
    rows: [
      ['Mozzarella', 'Dairy', '4 kg', '5 kg', 'Fresh Farms', 'Low stock'],
      ['Coffee beans', 'Beverage', '12 kg', '4 kg', 'Roast House', 'In stock'],
      ['Basmati rice', 'Pantry', '18 kg', '8 kg', 'Grain Co.', 'In stock'],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.reservations,
    title: 'Reservations',
    subtitle: 'Manage upcoming guests, tables, and special requests.',
    actionLabel: 'New Reservation',
    icon: Icons.event_seat_outlined,
    summaryLabels: ['Today’s reservations', 'Seated guests', 'Upcoming'],
    columns: ['Guest', 'Date & time', 'Party size', 'Table', 'Status', 'Notes'],
    rows: [
      [
        'Priya Menon',
        'Today · 7:30 PM',
        '4 guests',
        'Table 8',
        'Confirmed',
        'Window seat',
      ],
      [
        'Rohan Gupta',
        'Today · 8:00 PM',
        '2 guests',
        'Table 3',
        'Confirmed',
        'Anniversary',
      ],
      [
        'Kavya Iyer',
        'Today · 8:30 PM',
        '6 guests',
        'Terrace 2',
        'Pending',
        '—',
      ],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.reports,
    title: 'Reports & Analytics',
    subtitle: 'Review sales, orders, products, and operational performance.',
    actionLabel: 'Export Report',
    icon: Icons.file_download_outlined,
    summaryLabels: ['Sales this month', 'Net sales', 'Avg. order value'],
    columns: ['Report', 'Period', 'Revenue', 'Orders', 'Change', 'Updated'],
    rows: [
      ['Sales summary', 'July 2026', '₹8,42,520', '3,124', '+12.4%', 'Today'],
      ['Item performance', 'July 2026', '₹8,42,520', '3,124', '+8.1%', 'Today'],
      [
        'Staff performance',
        'July 2026',
        '₹8,42,520',
        '3,124',
        '+5.6%',
        'Today',
      ],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.branches,
    title: 'Branches & Operations',
    subtitle: 'Review restaurant locations and daily operating status.',
    actionLabel: 'Add Branch',
    icon: Icons.add_business_outlined,
    summaryLabels: ['Active branches', 'Open now', 'Today’s sales'],
    columns: [
      'Branch',
      'Location',
      'Manager',
      'Tables',
      'Status',
      'Today’s sales',
    ],
    rows: [
      ['La Rosetta Main', 'Green Park', 'Meera Das', '22', 'Open', '₹48,250'],
      [
        'La Rosetta North',
        'Model Town',
        'Sahil Kapoor',
        '18',
        'Open',
        '₹36,480',
      ],
      ['La Rosetta Airport', 'Terminal 2', 'Vikram Shah', '14', 'Closed', '₹0'],
    ],
  ),
  TavolaFeatureConfig(
    route: AppRoutes.settings,
    title: 'Settings',
    subtitle:
        'Configure restaurant details, taxes, printers, and notifications.',
    actionLabel: 'Save Changes',
    icon: Icons.settings_outlined,
    summaryLabels: ['Restaurant profile', 'Billing settings', 'Notifications'],
    columns: [
      'Setting',
      'Category',
      'Current value',
      'Status',
      'Updated',
      'Owner',
    ],
    rows: [
      ['GST rate', 'Billing', '5%', 'Active', 'Today', 'Rahul Sharma'],
      [
        'Service charge',
        'Billing',
        '10%',
        'Active',
        'Yesterday',
        'Rahul Sharma',
      ],
      [
        'Order alerts',
        'Notifications',
        'Enabled',
        'Active',
        'Today',
        'Meera Das',
      ],
    ],
  ),
];
