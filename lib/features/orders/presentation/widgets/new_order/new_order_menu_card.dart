import 'package:flutter/material.dart';

import '../../../../../core/design/tavola_colors.dart';
import '../../../../../core/design/tavola_tokens.dart';
import '../../../../../core/formatters/app_formatters.dart';
import '../../../../menu/domain/entities/menu_entities.dart';

/// A menu item card matching the visual hierarchy of the new-order handoff.
class NewOrderMenuCard extends StatelessWidget {
  const NewOrderMenuCard({
    super.key,
    required this.item,
    required this.onAdd,
    this.quantity = 0,
  });

  final MenuItem item;
  final VoidCallback? onAdd;
  final int quantity;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${item.name}, ${AppFormatters.currency.format(item.priceMinor / 100)}',
    child: Material(
      color: TavolaColors.surface,
      borderRadius: TavolaRadius.medium,
      child: InkWell(
        onTap: item.isOrderable ? onAdd : null,
        borderRadius: TavolaRadius.medium,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: TavolaColors.border),
            borderRadius: TavolaRadius.medium,
            boxShadow: const [
              BoxShadow(
                color: TavolaColors.shadow,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _MenuImage(item: item)),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TavolaSpace.sm,
                  TavolaSpace.sm,
                  TavolaSpace.sm,
                  TavolaSpace.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TavolaColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: TavolaSpace.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppFormatters.currency.format(
                              item.priceMinor / 100,
                            ),
                            style: const TextStyle(
                              color: TavolaColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: item.isOrderable ? onAdd : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TavolaColors.textPrimary,
                            minimumSize: const Size(56, 32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: TavolaSpace.sm,
                            ),
                            side: const BorderSide(color: TavolaColors.border),
                            shape: const RoundedRectangleBorder(
                              borderRadius: TavolaRadius.small,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(quantity > 0 ? 'Add $quantity' : 'Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MenuImage extends StatelessWidget {
  const _MenuImage({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final imagePath = item.imagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.network(
        imagePath,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _MenuImagePlaceholder(),
      );
    }
    return const _MenuImagePlaceholder();
  }
}

class _MenuImagePlaceholder extends StatelessWidget {
  const _MenuImagePlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: TavolaColors.surfaceVariant,
    child: Center(
      child: Icon(
        Icons.room_service_outlined,
        size: 30,
        color: TavolaColors.textMuted,
      ),
    ),
  );
}
