import 'package:flutter/material.dart';

import '../design/tavola_colors.dart';
import '../design/tavola_tokens.dart';

class TavolaMetricCard extends StatelessWidget {
  const TavolaMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    required this.detail,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.15),
              borderRadius: TavolaRadius.medium,
            ),
            child: Padding(
              padding: const EdgeInsets.all(TavolaSpace.xs),
              child: Icon(icon, color: tone, size: TavolaSize.iconMedium),
            ),
          ),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: TavolaSpace.xxs),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: TavolaSpace.xxs),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: TavolaColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

class TavolaStatusBadge extends StatelessWidget {
  const TavolaStatusBadge({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TavolaSpace.xs,
        vertical: TavolaSpace.xxs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    ),
  );
}

class TavolaPageHeader extends StatelessWidget {
  const TavolaPageHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: TavolaSpace.xxs),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      if (actionLabel != null)
        FilledButton.icon(
          onPressed: onAction,
          icon: Icon(actionIcon ?? Icons.add_rounded),
          label: Text(actionLabel!),
        ),
    ],
  );
}

class TavolaPanel extends StatelessWidget {
  const TavolaPanel({
    required this.child,
    this.padding = const EdgeInsets.all(TavolaSpace.lg),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}
