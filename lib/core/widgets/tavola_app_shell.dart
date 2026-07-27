import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/tavola_breakpoints.dart';
import '../design/tavola_colors.dart';
import '../design/tavola_tokens.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/domain/entities/restaurant_membership.dart';

class TavolaNavItem {
  const TavolaNavItem({
    required this.label,
    required this.route,
    required this.icon,
    this.section,
  });

  final String label;
  final String route;
  final IconData icon;
  final String? section;
}

const tavolaNavigation = [
  TavolaNavItem(
    label: 'Dashboard',
    route: '/',
    icon: Icons.grid_view_rounded,
    section: 'Overview',
  ),
  TavolaNavItem(
    label: 'Orders',
    route: '/orders',
    icon: Icons.receipt_long_outlined,
    section: 'Operations',
  ),
  TavolaNavItem(
    label: 'Tables',
    route: '/tables',
    icon: Icons.table_restaurant_outlined,
  ),
  TavolaNavItem(
    label: 'Kitchen',
    route: '/kitchen',
    icon: Icons.soup_kitchen_outlined,
  ),
  TavolaNavItem(
    label: 'Billing',
    route: '/billing',
    icon: Icons.payments_outlined,
  ),
  TavolaNavItem(
    label: 'Menu',
    route: '/menu',
    icon: Icons.restaurant_menu_outlined,
    section: 'Manage',
  ),
  TavolaNavItem(
    label: 'Customers',
    route: '/customers',
    icon: Icons.people_outline,
  ),
  TavolaNavItem(label: 'Staff', route: '/staff', icon: Icons.badge_outlined),
  TavolaNavItem(
    label: 'Discounts',
    route: '/discounts',
    icon: Icons.local_offer_outlined,
  ),
  TavolaNavItem(
    label: 'Inventory',
    route: '/inventory',
    icon: Icons.inventory_2_outlined,
  ),
  TavolaNavItem(
    label: 'Reservations',
    route: '/reservations',
    icon: Icons.event_seat_outlined,
  ),
  TavolaNavItem(
    label: 'Reports',
    route: '/reports',
    icon: Icons.bar_chart_outlined,
    section: 'Insights',
  ),
  TavolaNavItem(
    label: 'Branches',
    route: '/branches',
    icon: Icons.account_tree_outlined,
  ),
  TavolaNavItem(
    label: 'Settings',
    route: '/settings',
    icon: Icons.settings_outlined,
  ),
];

class TavolaAppShell extends StatelessWidget {
  const TavolaAppShell({
    required this.activeRoute,
    required this.child,
    this.topBar,
    super.key,
  });

  final String activeRoute;
  final Widget child;
  final Widget? topBar;

  @override
  Widget build(BuildContext context) {
    final compact =
        TavolaBreakpoints.isMedium(context) ||
        TavolaBreakpoints.isCompact(context);
    return Scaffold(
      drawer: compact
          ? Drawer(child: _Sidebar(activeRoute: activeRoute))
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!compact)
              SizedBox(
                width: TavolaSize.sidebarWidth,
                child: _Sidebar(activeRoute: activeRoute),
              ),
            Expanded(
              child: Column(
                children: [
                  topBar ?? _TopBar(showMenu: compact),
                  Expanded(
                    child: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: TavolaSize.maxContentWidth,
                          ),
                          child: child,
                        ),
                      ),
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
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({this.activeRoute});

  final String? activeRoute;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: TavolaColors.primary,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TavolaSpace.md,
          TavolaSpace.lg,
          TavolaSpace.md,
          TavolaSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Brand(),
            const SizedBox(height: TavolaSpace.lg),
            Expanded(
              child: ListView.builder(
                itemCount: tavolaNavigation.length,
                itemBuilder: (context, index) {
                  final item = tavolaNavigation[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.section != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                          child: Text(
                            item.section!.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: TavolaColors.textMuted,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ),
                      _NavigationTile(
                        item: item,
                        selected: item.route == activeRoute,
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(color: Color(0x1FFFFFFF)),
            const SizedBox(height: TavolaSpace.sm),
            const _AccountSummary(),
          ],
        ),
      ),
    ),
  );
}

class _Brand extends ConsumerWidget {
  const _Brand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantName =
        ref.watch(currentMembershipProvider).dataOrNull?.restaurantName ??
        'Loading…';
    return Row(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: TavolaColors.accent,
            borderRadius: TavolaRadius.medium,
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                'T',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: TavolaColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: TavolaSpace.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tavola',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              restaurantName.toUpperCase(),
              style: const TextStyle(
                color: TavolaColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({required this.item, required this.selected});

  final TavolaNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Material(
      color: selected ? const Color(0x24F59E0B) : Colors.transparent,
      borderRadius: TavolaRadius.medium,
      child: InkWell(
        borderRadius: TavolaRadius.medium,
        onTap: () {
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.of(context).pop();
          }
          context.go(item.route);
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.sm),
          decoration: selected
              ? const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: TavolaColors.accent, width: 3),
                  ),
                )
              : null,
          child: Row(
            children: [
              Icon(
                item.icon,
                size: TavolaSize.iconMedium,
                color: selected ? Colors.white : TavolaColors.darkTextSecondary,
              ),
              const SizedBox(width: TavolaSpace.sm),
              Text(
                item.label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : TavolaColors.darkTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.showMenu});

  final bool showMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).dataOrNull;
    final membership = ref.watch(currentMembershipProvider).dataOrNull;
    final name = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!.trim()
        : user?.email ?? 'Account';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      height: TavolaSize.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenu)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          if (showMenu) const SizedBox(width: TavolaSpace.xs),
          if (!showMenu)
            const Expanded(
              child: SizedBox(
                width: 320,
                child: TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Search orders, tables, menu items…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            )
          else
            const Expanded(
              child: Text(
                'Tavola',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          IconButton(
            onPressed: () {},
            icon: const Badge(child: Icon(Icons.notifications_none_rounded)),
          ),
          const SizedBox(width: TavolaSpace.sm),
          CircleAvatar(
            radius: 16,
            backgroundColor: TavolaColors.primary,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: TavolaSpace.xs),
          if (!showMenu)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  membership?.restaurantName ?? 'Your workspace',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TavolaColors.textMuted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AccountSummary extends ConsumerWidget {
  const _AccountSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).dataOrNull;
    final membership = ref.watch(currentMembershipProvider).dataOrNull;
    final name = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!
        : user?.email ?? 'Account';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted && ref.read(authControllerProvider).hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not sign out. Try again.')),
            );
          }
        },
        borderRadius: TavolaRadius.medium,
        child: Padding(
          padding: const EdgeInsets.all(TavolaSpace.xs),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: TavolaColors.darkSurfaceVariant,
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: TavolaSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      membership?.role.label ?? 'Account',
                      style: const TextStyle(
                        color: TavolaColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.logout_rounded,
                size: TavolaSize.iconSmall,
                color: TavolaColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
