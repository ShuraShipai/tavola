import 'package:flutter/material.dart';

import '../../../../../core/design/tavola_colors.dart';
import '../../../../../core/design/tavola_tokens.dart';
import '../../../../../core/formatters/app_formatters.dart';
import '../../../domain/entities/restaurant_order.dart';
import 'order_ticket_line.dart';

/// The persistent order summary card shown alongside the new-order menu.
class NewOrderTicket extends StatelessWidget {
  const NewOrderTicket({
    super.key,
    required this.lines,
    required this.onIncrementLine,
    required this.onDecrementLine,
    required this.onSendToKitchen,
    required this.onHoldOrder,
    this.taxAmount = 0,
    this.serviceChargeAmount = 0,
    this.isSubmitting = false,
    this.sendLabel = 'Send to Kitchen',
  });

  final List<OrderLine> lines;
  final ValueChanged<OrderLine> onIncrementLine;
  final ValueChanged<OrderLine> onDecrementLine;
  final VoidCallback? onSendToKitchen;
  final VoidCallback? onHoldOrder;
  final int taxAmount;
  final int serviceChargeAmount;
  final bool isSubmitting;
  final String sendLabel;

  int get _subtotal => lines.fold(0, (sum, line) => sum + line.lineTotalAmount);
  int get _quantity =>
      lines.fold(0, (sum, line) => sum + line.quantity.toInt());
  int get _total => _subtotal + taxAmount + serviceChargeAmount;

  @override
  Widget build(BuildContext context) => Container(
    width: 320,
    padding: const EdgeInsets.all(TavolaSpace.md),
    decoration: BoxDecoration(
      color: TavolaColors.surface,
      border: Border.all(color: TavolaColors.border),
      borderRadius: TavolaRadius.large,
      boxShadow: const [
        BoxShadow(
          color: TavolaColors.shadow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Order Ticket',
                style: TextStyle(
                  color: TavolaColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _ItemCountChip(lineCount: lines.length, quantity: _quantity),
          ],
        ),
        const SizedBox(height: TavolaSpace.md),
        if (lines.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: TavolaSpace.xxl),
            child: Text(
              'Add items from the menu to start this order.',
              textAlign: TextAlign.center,
              style: TextStyle(color: TavolaColors.textMuted, fontSize: 13),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              itemCount: lines.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: TavolaColors.border),
              itemBuilder: (context, index) {
                final line = lines[index];
                return OrderTicketLine(
                  line: line,
                  enabled: !isSubmitting,
                  onIncrement: () => onIncrementLine(line),
                  onDecrement: () => onDecrementLine(line),
                );
              },
            ),
          ),
        const Divider(height: TavolaSpace.xxl, color: TavolaColors.border),
        _AmountRow(label: 'Subtotal', amount: _subtotal),
        if (taxAmount > 0) ...[
          const SizedBox(height: TavolaSpace.xs),
          _AmountRow(label: 'Tax', amount: taxAmount),
        ],
        if (serviceChargeAmount > 0) ...[
          const SizedBox(height: TavolaSpace.xs),
          _AmountRow(label: 'Service Charge', amount: serviceChargeAmount),
        ],
        const SizedBox(height: TavolaSpace.sm),
        _AmountRow(label: 'Total', amount: _total, bold: true),
        const SizedBox(height: TavolaSpace.lg),
        SizedBox(
          height: TavolaSize.buttonHeight + 4,
          child: FilledButton(
            onPressed: isSubmitting || lines.isEmpty ? null : onSendToKitchen,
            style: FilledButton.styleFrom(
              backgroundColor: TavolaColors.accent,
              foregroundColor: TavolaColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(sendLabel),
          ),
        ),
        const SizedBox(height: TavolaSpace.sm),
        SizedBox(
          height: TavolaSize.buttonHeight,
          child: OutlinedButton(
            onPressed: isSubmitting || lines.isEmpty ? null : onHoldOrder,
            style: OutlinedButton.styleFrom(
              foregroundColor: TavolaColors.textPrimary,
              side: const BorderSide(color: TavolaColors.borderStrong),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Hold Order'),
          ),
        ),
      ],
    ),
  );
}

class _ItemCountChip extends StatelessWidget {
  const _ItemCountChip({required this.lineCount, required this.quantity});

  final int lineCount;
  final int quantity;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: TavolaSpace.sm,
      vertical: TavolaSpace.xs,
    ),
    decoration: const BoxDecoration(
      color: TavolaColors.border,
      borderRadius: TavolaRadius.extraLarge,
    ),
    child: Text(
      '$lineCount ${lineCount == 1 ? 'line item' : 'line items'} · $quantity ${quantity == 1 ? 'unit' : 'units'}',
      style: const TextStyle(
        color: TavolaColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  final String label;
  final int amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: TavolaColors.textPrimary,
      fontSize: bold ? 16 : 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: bold
                ? style
                : style.copyWith(color: TavolaColors.textSecondary),
          ),
        ),
        Text(AppFormatters.currency.format(amount / 100), style: style),
      ],
    );
  }
}
