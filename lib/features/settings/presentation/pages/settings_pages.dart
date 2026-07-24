import 'package:flutter/material.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_ui_components.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => _Shell(
    title: 'Settings',
    subtitle:
        'Configure restaurant operations, billing, devices and your account',
    child: LayoutBuilder(
      builder: (_, c) => GridView.count(
        crossAxisCount: c.maxWidth < 700 ? 2 : 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: const [
          _Card(
            'Restaurant Profile',
            'Business identity, address, tax registration and branding.',
            Icons.storefront_outlined,
          ),
          _Card(
            'Billing & Tax',
            'GST, service charge, invoice numbering and receipt notes.',
            Icons.receipt_long_outlined,
          ),
          _Card(
            'Tables & Areas',
            'Dining areas, tables, capacities and online reservations.',
            Icons.table_restaurant_outlined,
          ),
          _Card(
            'Payments',
            'Cash, card terminals, UPI and gift cards.',
            Icons.payments_outlined,
          ),
          _Card(
            'Printers',
            'Receipt and kitchen printer routing.',
            Icons.print_outlined,
          ),
          _Card(
            'App Preferences',
            'Order behavior, notifications, display and language.',
            Icons.tune_rounded,
          ),
        ],
      ),
    ),
  );
}

class RestaurantProfilePage extends StatelessWidget {
  const RestaurantProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const _Form(
    title: 'Restaurant Profile',
    subtitle: 'Business identity, address, tax registration and branding',
    fields: [
      'Restaurant name',
      'Restaurant type',
      'Phone number',
      'Email address',
      'Address',
      'GSTIN',
    ],
  );
}

class BillingTaxSettingsPage extends StatelessWidget {
  const BillingTaxSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => const _Form(
    title: 'Billing & Tax',
    subtitle: 'Configure invoices, taxes and service charges',
    fields: [
      'Default GST rate',
      'Price display',
      'Invoice prefix',
      'Next invoice number',
      'Footer note',
    ],
  );
}

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});
  @override
  Widget build(BuildContext context) => _Shell(
    title: 'Payment Methods',
    subtitle: 'Choose which payment options appear at checkout',
    child: const TavolaPanel(
      child: Column(
        children: [
          _Toggle('Cash', 'Track cash received and change returned', true),
          _Toggle(
            'Credit & debit cards',
            'Razorpay Terminal · Connected',
            true,
          ),
          _Toggle('UPI', 'Dynamic QR and manual UTR entry', true),
          _Toggle('Gift cards', 'Accept Tavola gift card balances', false),
        ],
      ),
    ),
  );
}

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => _Shell(
    title: 'App Settings',
    subtitle: 'Display, notification and order preferences',
    child: const TavolaPanel(
      child: Column(
        children: [
          _Toggle(
            'Auto-accept kitchen orders',
            'Send new orders directly to KDS',
            true,
          ),
          _Toggle(
            'Require table guest count',
            'Ask before creating dine-in orders',
            true,
          ),
          _Toggle(
            'Allow order holds',
            'Staff can save unfinished orders',
            true,
          ),
          _Toggle('Sound notifications', 'Play sound for new orders', true),
          _Toggle(
            'Compact table density',
            'Show more rows on each page',
            false,
          ),
        ],
      ),
    ),
  );
}

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const _Form(
    title: 'My Profile',
    subtitle: 'Personal information and account preferences',
    fields: [
      'First name',
      'Last name',
      'Email',
      'Phone',
      'Language',
      'Timezone',
    ],
  );
}

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});
  @override
  Widget build(BuildContext context) => const _Form(
    title: 'Change Password',
    subtitle: 'Use a strong password you do not use elsewhere',
    fields: ['Current password', 'New password', 'Confirm new password'],
  );
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});
  @override
  Widget build(BuildContext context) => _Shell(
    title: 'Help & Support',
    subtitle: 'Guides, contact options and product information',
    child: const TavolaPanel(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.menu_book_outlined),
            title: Text('Getting started'),
            subtitle: Text('Learn orders, tables, billing and daily setup.'),
          ),
          ListTile(
            leading: Icon(Icons.support_agent_outlined),
            title: Text('Contact support'),
            subtitle: Text('Chat with Tavola support, available 24×7.'),
          ),
          ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('System status'),
            subtitle: Text('All Tavola services are operational.'),
          ),
        ],
      ),
    ),
  );
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => TavolaAppShell(
    activeRoute: '/settings',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(TavolaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TavolaPageHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 24),
          child,
        ],
      ),
    ),
  );
}

class _Form extends StatelessWidget {
  const _Form({
    required this.title,
    required this.subtitle,
    required this.fields,
  });
  final String title, subtitle;
  final List<String> fields;
  @override
  Widget build(BuildContext context) => _Shell(
    title: title,
    subtitle: subtitle,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: TavolaPanel(
        child: Column(
          children: [
            ...fields.map(
              (x) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextField(
                  obscureText: x.contains('password'),
                  decoration: InputDecoration(labelText: x),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card(this.title, this.copy, this.icon);
  final String title, copy;
  final IconData icon;
  @override
  Widget build(BuildContext context) => TavolaPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(copy),
        const Spacer(),
        OutlinedButton(onPressed: () {}, child: const Text('Open')),
      ],
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.title, this.copy, this.value);
  final String title, copy;
  final bool value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(copy),
    trailing: Switch(value: value, onChanged: null),
  );
}
