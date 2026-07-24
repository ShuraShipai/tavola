import 'package:flutter/material.dart';

import '../design/tavola_breakpoints.dart';
import '../design/tavola_colors.dart';
import '../design/tavola_tokens.dart';
import 'tavola_app_shell.dart';
import 'tavola_ui_components.dart';

class TavolaFeatureConfig {
  const TavolaFeatureConfig({
    required this.route,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.summaryLabels,
    required this.columns,
    required this.rows,
  });

  final String route;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final List<String> summaryLabels;
  final List<String> columns;
  final List<List<String>> rows;
}

class TavolaFeaturePage extends StatelessWidget {
  const TavolaFeaturePage({required this.config, super.key});

  final TavolaFeatureConfig config;

  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: config.route,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TavolaPageHeader(
            title: config.title,
            subtitle: config.subtitle,
            actionLabel: config.actionLabel,
            actionIcon: config.icon,
          ),
          const SizedBox(height: TavolaSpace.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= TavolaBreakpoints.expanded
                  ? 3
                  : constraints.maxWidth >= TavolaBreakpoints.compact
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: TavolaSpace.md,
                  mainAxisSpacing: TavolaSpace.md,
                  childAspectRatio: 2.3,
                ),
                itemCount: config.summaryLabels.length,
                itemBuilder: (context, index) => TavolaMetricCard(
                  label: config.summaryLabels[index],
                  value: ['24', '₹12,480', '8'][index % 3],
                  icon: config.icon,
                  tone: [
                    TavolaColors.accent,
                    TavolaColors.info,
                    TavolaColors.success,
                  ][index % 3],
                  detail: 'Updated just now',
                ),
              );
            },
          ),
          const SizedBox(height: TavolaSpace.lg),
          TavolaPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(TavolaSpace.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          enabled: false,
                          decoration: InputDecoration(
                            hintText: 'Search ${config.title.toLowerCase()}…',
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: TavolaSpace.sm),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Filter'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    columns: config.columns
                        .map((column) => DataColumn(label: Text(column)))
                        .toList(),
                    rows: config.rows
                        .map(
                          (row) => DataRow(
                            cells: row
                                .map((cell) => DataCell(Text(cell)))
                                .toList(),
                          ),
                        )
                        .toList(),
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
