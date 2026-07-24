import 'package:flutter/material.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class KitchenPage extends StatelessWidget {
  const KitchenPage({super.key});
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/kitchen',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TavolaPageHeader(
            title: 'Kitchen Display System',
            subtitle: '18 active tickets across all stations',
            actionLabel: 'Kitchen Settings',
            actionIcon: Icons.settings_outlined,
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth >= TavolaBreakpoints.medium
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _KitchenColumn(
                          title: 'New',
                          count: '4',
                          color: TavolaColors.info,
                          tickets: [
                            ('Table 7', 'Just now', '1× Veg Biryani\n1× Raita'),
                            ('Takeaway #221', '1 min ago', '2× Cold Coffee'),
                          ],
                        ),
                      ),
                      SizedBox(width: TavolaSpace.md),
                      Expanded(
                        child: _KitchenColumn(
                          title: 'Preparing',
                          count: '9',
                          color: TavolaColors.accentDark,
                          tickets: [
                            (
                              'Table 5',
                              '6 min',
                              '1× Margherita Pizza\n2× Cold Coffee\n1× Paneer Tikka',
                            ),
                            (
                              'Table 2',
                              '11 min',
                              '3× Butter Naan\n1× Butter Chicken',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: TavolaSpace.md),
                      Expanded(
                        child: _KitchenColumn(
                          title: 'Ready',
                          count: '5',
                          color: TavolaColors.success,
                          tickets: [
                            ('Takeaway #219', 'Ready 2 min', '1× Cold Coffee'),
                            (
                              'Table 9',
                              'Ready 4 min',
                              '4× Roti\n1× Paneer Tikka',
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Column(
                    children: [
                      _KitchenColumn(
                        title: 'New',
                        count: '4',
                        color: TavolaColors.info,
                        tickets: [
                          ('Table 7', 'Just now', '1× Veg Biryani\n1× Raita'),
                        ],
                      ),
                      SizedBox(height: TavolaSpace.md),
                      _KitchenColumn(
                        title: 'Preparing',
                        count: '9',
                        color: TavolaColors.accentDark,
                        tickets: [
                          (
                            'Table 5',
                            '6 min',
                            '1× Margherita Pizza\n2× Cold Coffee\n1× Paneer Tikka',
                          ),
                        ],
                      ),
                      SizedBox(height: TavolaSpace.md),
                      _KitchenColumn(
                        title: 'Ready',
                        count: '5',
                        color: TavolaColors.success,
                        tickets: [
                          ('Takeaway #219', 'Ready 2 min', '1× Cold Coffee'),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class _KitchenColumn extends StatelessWidget {
  const _KitchenColumn({
    required this.title,
    required this.count,
    required this.color,
    required this.tickets,
  });
  final String title;
  final String count;
  final Color color;
  final List<(String, String, String)> tickets;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: TavolaSpace.xs),
          TavolaStatusBadge(label: count, color: TavolaColors.textSecondary),
        ],
      ),
      const SizedBox(height: TavolaSpace.md),
      ...tickets.map(
        (ticket) => Padding(
          padding: const EdgeInsets.only(bottom: TavolaSpace.md),
          child: TavolaPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      ticket.$2,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TavolaColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TavolaSpace.md),
                Text(
                  ticket.$3,
                  style: const TextStyle(height: 1.7, fontSize: 13),
                ),
                const SizedBox(height: TavolaSpace.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text(
                      title == 'New'
                          ? 'Start Preparing'
                          : title == 'Preparing'
                          ? 'Mark Ready'
                          : 'Mark Served',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
