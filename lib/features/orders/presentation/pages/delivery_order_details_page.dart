import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/restaurant_order.dart';
import '../providers/new_order_draft_provider.dart';

/// Delivery setup screen (handoff screen 82) before staff choose menu items.
class DeliveryOrderDetailsPage extends ConsumerStatefulWidget {
  const DeliveryOrderDetailsPage({super.key});

  @override
  ConsumerState<DeliveryOrderDetailsPage> createState() =>
      _DeliveryOrderDetailsPageState();
}

class _DeliveryOrderDetailsPageState
    extends ConsumerState<DeliveryOrderDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _customer = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _instructions = TextEditingController();
  String _partner = 'Restaurant delivery';
  String _estimate = '45 minutes';
  bool _contactless = true;

  @override
  void dispose() {
    _customer.dispose();
    _phone.dispose();
    _address.dispose();
    _instructions.dispose();
    super.dispose();
  }

  void _continueToMenu() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(newOrderDraftProvider.notifier)
        .selectOrderType(RestaurantOrderType.delivery);
    context.go(AppRoutes.ordersNew);
  }

  void _cancelDelivery() {
    ref.read(newOrderDraftProvider.notifier).reset();
    context.go(AppRoutes.orders);
  }

  void setPartner(String value) => setState(() => _partner = value);
  void setEstimate(String value) => setState(() => _estimate = value);
  void setContactless(bool value) => setState(() => _contactless = value);

  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: AppRoutes.orders,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(onCancel: _cancelDelivery, onContinue: _continueToMenu),
                const SizedBox(height: TavolaSpace.xl),
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 850
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _DeliveryDetails(form: this)),
                            const SizedBox(width: TavolaSpace.lg),
                            SizedBox(
                              width: 360,
                              child: _OrderSetup(state: this),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _DeliveryDetails(form: this),
                            const SizedBox(height: TavolaSpace.lg),
                            _OrderSetup(state: this),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onCancel, required this.onContinue});
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 700
        ? Row(
            children: [
              Expanded(child: _copy(context)),
              _actions(),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _copy(context),
              const SizedBox(height: TavolaSpace.md),
              _actions(),
            ],
          ),
  );

  Widget _copy(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'New Delivery Order',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: TavolaSpace.xxs),
      Text(
        'Customer, address and fulfilment information',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: TavolaColors.textSecondary),
      ),
    ],
  );

  Widget _actions() => Wrap(
    spacing: 10,
    children: [
      OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
      FilledButton(
        onPressed: onContinue,
        child: const Text('Continue to Menu'),
      ),
    ],
  );
}

class _DeliveryDetails extends StatelessWidget {
  const _DeliveryDetails({required this.form});
  final _DeliveryOrderDetailsPageState form;

  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: TavolaSpace.md),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: TavolaSpace.md,
            runSpacing: TavolaSpace.md,
            children: [
              SizedBox(
                width: constraints.maxWidth >= 560
                    ? (constraints.maxWidth - TavolaSpace.md) / 2
                    : constraints.maxWidth,
                child: _field(
                  'Customer name',
                  form._customer,
                  'Enter customer name',
                ),
              ),
              SizedBox(
                width: constraints.maxWidth >= 560
                    ? (constraints.maxWidth - TavolaSpace.md) / 2
                    : constraints.maxWidth,
                child: _field(
                  'Phone number',
                  form._phone,
                  'Enter phone number',
                  type: TextInputType.phone,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TavolaSpace.md),
        _field(
          'Delivery address',
          form._address,
          'Enter delivery address',
          lines: 3,
        ),
        const SizedBox(height: TavolaSpace.md),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: TavolaSpace.md,
            runSpacing: TavolaSpace.md,
            children: [
              SizedBox(
                width: constraints.maxWidth >= 560
                    ? (constraints.maxWidth - TavolaSpace.md) / 2
                    : constraints.maxWidth,
                child: _select('Delivery partner', form._partner, const [
                  'Restaurant delivery',
                  'Customer pickup',
                  'Third-party partner',
                ], form.setPartner),
              ),
              SizedBox(
                width: constraints.maxWidth >= 560
                    ? (constraints.maxWidth - TavolaSpace.md) / 2
                    : constraints.maxWidth,
                child: _select('Estimated delivery', form._estimate, const [
                  '30 minutes',
                  '45 minutes',
                  '60 minutes',
                ], form.setEstimate),
              ),
            ],
          ),
        ),
        const SizedBox(height: TavolaSpace.md),
        _field(
          'Delivery instructions',
          form._instructions,
          'Landmark, gate code or contact preference',
          lines: 3,
          required: false,
        ),
      ],
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    int lines = 1,
    bool required = true,
    TextInputType? type,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: TavolaSpace.xs),
      TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: type,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? '$label is required'
                  : null
            : null,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );

  Widget _select(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: TavolaSpace.xs),
      DropdownButtonFormField<String>(
        initialValue: value,
        items: options
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) => onChanged(value!),
      ),
    ],
  );
}

class _OrderSetup extends StatelessWidget {
  const _OrderSetup({required this.state});
  final _DeliveryOrderDetailsPageState state;

  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order setup', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TavolaSpace.md),
        _row('Order type', 'Delivery'),
        _row('Delivery fee', '₹60'),
        _row('Minimum order', '₹300'),
        const Divider(),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Contactless delivery'),
          subtitle: const Text('Leave at the customer\'s door'),
          value: state._contactless,
          activeThumbColor: TavolaColors.accent,
          onChanged: state.setContactless,
        ),
        const Divider(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TavolaSpace.md),
          decoration: const BoxDecoration(
            color: TavolaColors.infoLight,
            borderRadius: TavolaRadius.small,
          ),
          child: const Text(
            'Delivery zone verified · 4.2 km from restaurant',
            style: TextStyle(color: TavolaColors.info),
          ),
        ),
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TavolaSpace.sm),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: TavolaColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
