part of 'order_states_pages.dart';

class _OrderShell extends StatelessWidget {
  const _OrderShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.badge,
    this.actions = const [],
  });
  final String title;
  final String subtitle;
  final Widget child;
  final TavolaStatusBadge? badge;
  final List<_Action> actions;
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/orders',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders  ›  $title',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: TavolaColors.textMuted),
          ),
          const SizedBox(height: TavolaSpace.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: TavolaSpace.sm,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: TavolaSpace.xs,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      // The current SDK does not parse null-aware list elements.
                      // ignore: use_null_aware_elements
                      if (badge case final activeBadge?) activeBadge,
                    ],
                  ),
                  const SizedBox(height: TavolaSpace.xxs),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              Wrap(
                spacing: TavolaSpace.xs,
                runSpacing: TavolaSpace.xs,
                children: actions.map((action) => action.build()).toList(),
              ),
            ],
          ),
          const SizedBox(height: TavolaSpace.lg),
          child,
        ],
      ),
    ),
  );
}

class _Action {
  const _Action(
    this.label,
    this.icon, {
    this.primary = false,
    this.danger = false,
    this.enabled = true,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final bool primary;
  final bool danger;
  final bool enabled;
  final VoidCallback? onTap;
  Widget build() => primary
      ? FilledButton.icon(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon),
          label: Text(label),
        )
      : OutlinedButton.icon(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, color: danger ? TavolaColors.error : null),
          label: Text(
            label,
            style: danger ? const TextStyle(color: TavolaColors.error) : null,
          ),
        );
}
