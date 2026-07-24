import 'package:flutter/material.dart';

import '../design/tavola_tokens.dart';

class TavolaLoadingIndicator extends StatelessWidget {
  const TavolaLoadingIndicator({this.label, super.key});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (label != null) ...[
          const SizedBox(height: TavolaSpace.sm),
          Text(label!),
        ],
      ],
    ),
  );
}

class TavolaEmptyState extends StatelessWidget {
  const TavolaEmptyState({
    required this.title,
    required this.message,
    this.action,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String title;
  final String message;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TavolaSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: TavolaSpace.md),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: TavolaSpace.xs),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: TavolaSpace.lg),
            action!,
          ],
        ],
      ),
    ),
  );
}

class TavolaErrorState extends StatelessWidget {
  const TavolaErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => TavolaEmptyState(
    title: 'Something went wrong',
    message: message,
    icon: Icons.error_outline,
    action: FilledButton.tonal(
      onPressed: onRetry,
      child: const Text('Try again'),
    ),
  );
}
