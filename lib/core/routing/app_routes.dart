abstract final class AppRoutes {
  static const dashboard = '/';
  static const orders = '/orders';
  static const tables = '/tables';
  static const kitchen = '/kitchen';
  static const billing = '/billing';
  static const menu = '/menu';
  static const menuNewItem = '/menu/items/new';
  static const menuCategories = '/menu/categories';
  static const customers = '/customers';
  static const staff = '/staff';
  static const discounts = '/discounts';
  static const inventory = '/inventory';
  static const reservations = '/reservations';
  static const reports = '/reports';
  static const branches = '/branches';
  static const settings = '/settings';
  static const splash = '/auth/splash';
  static const welcome = '/auth/welcome';
  static const login = '/auth/login';
  static const forgotPassword = '/auth/forgot-password';
  static const registerRestaurant = '/auth/register-restaurant';
  static const joinRestaurant = '/auth/join-restaurant';
  static const staffPin = '/auth/staff-pin';
  static const support = '/support';

  /// Auth routes that are safe to show before a Supabase session exists.
  static const unauthenticatedRoutes = {
    splash,
    welcome,
    login,
    forgotPassword,
    registerRestaurant,
    joinRestaurant,
    staffPin,
  };

  /// Routes an authenticated person without a restaurant membership may use.
  ///
  /// Joining a restaurant is intentionally kept available here: redirecting a
  /// newly invited employee to restaurant creation strands them in onboarding.
  static const membershipSetupRoutes = {registerRestaurant, joinRestaurant};
}

abstract final class AppRouteName {
  static const dashboard = 'dashboard';
  static const orders = 'orders';
  static const tables = 'tables';
  static const kitchen = 'kitchen';
  static const billing = 'billing';
  static const menu = 'menu';
  static const menuNewItem = 'menu-new-item';
  static const menuEditItem = 'menu-edit-item';
  static const menuCategories = 'menu-categories';
  static const customers = 'customers';
  static const staff = 'staff';
  static const discounts = 'discounts';
  static const inventory = 'inventory';
  static const reservations = 'reservations';
  static const reports = 'reports';
  static const branches = 'branches';
  static const settings = 'settings';
}
