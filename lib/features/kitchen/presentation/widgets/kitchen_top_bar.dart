import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'kitchen_active_ticket_count.dart';

class KitchenTopBar extends ConsumerWidget {
  const KitchenTopBar({this.activeTicketCount, super.key});
  final int? activeTicketCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).dataOrNull;
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
      decoration: const BoxDecoration(
        color: TavolaColors.surface,
        border: Border(bottom: BorderSide(color: TavolaColors.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Kitchen Display System',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (activeTicketCount != null) ...[
            KitchenActiveTicketCount(count: activeTicketCount!),
            const SizedBox(width: TavolaSpace.md),
          ],
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
        ],
      ),
    );
  }
}
