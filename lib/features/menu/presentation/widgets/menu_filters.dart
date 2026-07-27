import 'package:flutter/material.dart';

import '../../../../core/design/tavola_tokens.dart';
import '../../domain/entities/menu_entities.dart';

enum MenuAvailabilityFilter {
  all('All status'),
  available('Available'),
  hidden('Unavailable');

  const MenuAvailabilityFilter(this.label);
  final String label;
}

class MenuFilters extends StatelessWidget {
  const MenuFilters({
    required this.controller,
    required this.categories,
    required this.categoryId,
    required this.availability,
    required this.onChanged,
    required this.onCategoryChanged,
    required this.onAvailabilityChanged,
    super.key,
  });

  final TextEditingController controller;
  final List<MenuCategory> categories;
  final String? categoryId;
  final MenuAvailabilityFilter availability;
  final VoidCallback onChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<MenuAvailabilityFilter> onAvailabilityChanged;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TavolaSpace.md,
          vertical: 10,
        ),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 740;
        final search = TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search menu items',
          ),
        );
        final category = DropdownButtonFormField<String?>(
          initialValue: categoryId,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All categories')),
            ...categories.map(
              (item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
            ),
          ],
          onChanged: onCategoryChanged,
        );
        final status = DropdownButtonFormField<MenuAvailabilityFilter>(
          initialValue: availability,
          decoration: const InputDecoration(labelText: 'Status'),
          items: MenuAvailabilityFilter.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onAvailabilityChanged(value);
          },
        );
        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: TavolaSpace.sm),
              category,
              const SizedBox(height: TavolaSpace.sm),
              status,
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: TavolaSpace.sm),
            Expanded(child: category),
            const SizedBox(width: TavolaSpace.sm),
            Expanded(child: status),
          ],
        );
      },
    ),
  );
}
