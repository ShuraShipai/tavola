import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/restaurant_membership.dart';
import '../providers/auth_providers.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: TavolaColors.primary,
    body: SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(height: TavolaSpace.xs),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Mark(large: true),
              SizedBox(height: TavolaSpace.lg),
              Text('Tavola', style: _AuthText.splashTitle),
              SizedBox(height: TavolaSpace.xs),
              Text(
                'Effortless service, every table.',
                style: _AuthText.splashCopy,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: TavolaSpace.lg),
            child: Column(
              children: [
                SizedBox(
                  height: TavolaSize.iconMedium,
                  width: TavolaSize.iconMedium,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TavolaColors.accent,
                  ),
                ),
                SizedBox(height: TavolaSpace.sm),
                Text('Version 2.4.0', style: _AuthText.version),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    height: 200,
                    width: 200,
                    decoration: const BoxDecoration(
                      color: TavolaColors.accentLight,
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(90, 104),
                      ),
                    ),
                    child: const Icon(
                      Icons.soup_kitchen_outlined,
                      size: 84,
                      color: TavolaColors.accentDark,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(TavolaSpace.lg),
                child: Column(
                  children: [
                    Text(
                      'Run your restaurant, front to back',
                      textAlign: TextAlign.center,
                      style: _AuthText.welcomeTitle,
                    ),
                    const SizedBox(height: TavolaSpace.xs),
                    const Text(
                      'Take orders, manage tables, send tickets to the kitchen, and bill guests — all from one simple screen.',
                      textAlign: TextAlign.center,
                      style: _AuthText.body,
                    ),
                    const SizedBox(height: TavolaSpace.lg),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OnboardingDot(active: true),
                        _OnboardingDot(),
                        _OnboardingDot(),
                      ],
                    ),
                    const SizedBox(height: TavolaSpace.lg),
                    _PrimaryButton(
                      label: 'Get Started',
                      onPressed: () => context.go(AppRoutes.registerRestaurant),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('I already have an account — Log in'),
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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    _showAuthErrors(ref);
    return _LoginLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Welcome back', style: _AuthText.loginTitle),
            const SizedBox(height: TavolaSpace.xxs),
            const Text(
              'Log in to your restaurant dashboard',
              style: _AuthText.body,
            ),
            const SizedBox(height: TavolaSpace.lg),
            _AuthField(
              controller: _email,
              label: 'Email address',
              hint: 'you@restaurant.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            const SizedBox(height: TavolaSpace.md),
            _AuthField(
              controller: _password,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffix: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: _passwordValidator,
            ),
            const SizedBox(height: TavolaSpace.xs),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _rememberMe,
                    onChanged: (value) =>
                        setState(() => _rememberMe = value ?? false),
                    title: const Text('Remember me', style: _AuthText.checkbox),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: TavolaSpace.sm),
            _PrimaryButton(
              label: 'Sign In',
              loading: authState.isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                await ref
                    .read(authControllerProvider.notifier)
                    .signIn(
                      email: _email.text.trim(),
                      password: _password.text,
                    );
              },
            ),
            const _FormDivider(),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.staffPin),
              icon: const Icon(Icons.dialpad_outlined),
              label: const Text('Sign in with Staff PIN'),
            ),
            const SizedBox(height: TavolaSpace.lg),
            Center(
              child: _FooterText(
                prefix: 'New to Tavola? ',
                label: 'Create a restaurant account',
                onPressed: () => context.go(AppRoutes.registerRestaurant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    _showAuthErrors(ref);
    return _CenteredAuthCard(
      backLabel: 'Back to login',
      onBack: () => context.go(AppRoutes.login),
      icon: _sent ? Icons.mark_email_read_outlined : Icons.lock_outline,
      title: _sent ? 'Check your inbox' : 'Reset your password',
      subtitle: _sent
          ? 'If an account exists for ${_email.text.trim()}, we sent a password reset link.'
          : 'Enter the email associated with your account and we’ll send a link to reset your password.',
      child: _sent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PrimaryButton(
                  label: 'Send another link',
                  loading: authState.isLoading,
                  onPressed: _send,
                ),
                const SizedBox(height: TavolaSpace.md),
                const Text(
                  'Didn’t get an email? Check your spam folder.',
                  textAlign: TextAlign.center,
                  style: _AuthText.muted,
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AuthField(
                    controller: _email,
                    label: 'Email address',
                    hint: 'you@restaurant.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: TavolaSpace.md),
                  _PrimaryButton(
                    label: 'Send Reset Link',
                    loading: authState.isLoading,
                    onPressed: _send,
                  ),
                  const SizedBox(height: TavolaSpace.lg),
                  const Text(
                    'Didn’t get an email? Check your spam folder or resend.',
                    textAlign: TextAlign.center,
                    style: _AuthText.muted,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _send() async {
    if (!_sent && !_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text.trim());
    if (mounted && !ref.read(authControllerProvider).hasError) {
      setState(() => _sent = true);
    }
  }
}

class RegisterRestaurantPage extends ConsumerStatefulWidget {
  const RegisterRestaurantPage({super.key});
  @override
  ConsumerState<RegisterRestaurantPage> createState() =>
      _RegisterRestaurantPageState();
}

class _RegisterRestaurantPageState
    extends ConsumerState<RegisterRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final _restaurant = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _termsAccepted = true;
  final bool _obscurePassword = true;
  String _restaurantType = 'Casual Dining';
  @override
  void dispose() {
    for (final controller in [
      _restaurant,
      _name,
      _email,
      _phone,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).dataOrNull;
    final authState = ref.watch(authControllerProvider);
    final creatingRestaurant = user != null;
    _showAuthErrors(ref);
    return _CenteredAuthCard(
      wide: true,
      showMark: true,
      title: creatingRestaurant
          ? 'Create your restaurant'
          : 'Create your restaurant account',
      subtitle: creatingRestaurant
          ? 'One last step before your Tavola workspace is ready.'
          : 'Set up Tavola for your restaurant in a few minutes.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ResponsivePair(
              first: _AuthField(
                controller: _restaurant,
                label: 'Restaurant name',
                hint: 'La Rosetta Café',
              ),
              second: _SelectField(
                label: 'Restaurant type',
                value: _restaurantType,
                onChanged: (value) => setState(() => _restaurantType = value!),
                items: const [
                  'Casual Dining',
                  'Quick Service',
                  'Fine Dining',
                  'Café / Bakery',
                ],
              ),
            ),
            if (creatingRestaurant) ...[
              const SizedBox(height: TavolaSpace.md),
              _AuthField(
                controller: _phone,
                label: 'Phone number',
                hint: '+91 98765 43210',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ],
            if (!creatingRestaurant) ...[
              const SizedBox(height: TavolaSpace.md),
              _AuthField(
                controller: _name,
                label: 'Owner full name',
                hint: 'Rahul Sharma',
              ),
              const SizedBox(height: TavolaSpace.md),
              _ResponsivePair(
                first: _AuthField(
                  controller: _email,
                  label: 'Email address',
                  hint: 'you@restaurant.com',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),
                second: _AuthField(
                  controller: _phone,
                  label: 'Phone number',
                  hint: '+91 98765 43210',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: TavolaSpace.md),
              _ResponsivePair(
                first: _AuthField(
                  controller: _password,
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: _passwordValidator,
                ),
                second: _AuthField(
                  controller: _confirmPassword,
                  label: 'Confirm password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: (value) => value != _password.text
                      ? 'Passwords do not match.'
                      : null,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _termsAccepted,
                onChanged: (value) =>
                    setState(() => _termsAccepted = value ?? false),
                title: const Text(
                  'I agree to the Terms of Service and Privacy Policy',
                  style: _AuthText.checkbox,
                ),
              ),
            ],
            const SizedBox(height: TavolaSpace.sm),
            _PrimaryButton(
              label: creatingRestaurant
                  ? 'Create restaurant'
                  : 'Create Account',
              loading: authState.isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate() ||
                    (!creatingRestaurant && !_termsAccepted)) {
                  return;
                }
                final controller = ref.read(authControllerProvider.notifier);
                if (creatingRestaurant) {
                  await controller.createRestaurant(
                    name: _restaurant.text.trim(),
                    restaurantType: _restaurantType,
                    phone: _phone.text.trim().isEmpty
                        ? null
                        : _phone.text.trim(),
                  );
                } else {
                  await controller.signUp(
                    email: _email.text.trim(),
                    password: _password.text,
                    fullName: _name.text.trim(),
                    restaurantType: _restaurantType,
                    phone: _phone.text.trim().isEmpty
                        ? null
                        : _phone.text.trim(),
                  );
                }
              },
            ),
            if (!creatingRestaurant)
              Padding(
                padding: const EdgeInsets.only(top: TavolaSpace.lg),
                child: Center(
                  child: _FooterText(
                    prefix: 'Already have an account? ',
                    label: 'Log in',
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class JoinRestaurantPage extends ConsumerStatefulWidget {
  const JoinRestaurantPage({super.key});
  @override
  ConsumerState<JoinRestaurantPage> createState() => _JoinRestaurantPageState();
}

class _JoinRestaurantPageState extends ConsumerState<JoinRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantId = TextEditingController();
  final _inviteCode = TextEditingController();
  final _email = TextEditingController();
  @override
  void dispose() {
    _restaurantId.dispose();
    _inviteCode.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    _showAuthErrors(ref);
    return _CenteredAuthCard(
      backLabel: 'Back to login',
      onBack: () => context.go(AppRoutes.login),
      icon: Icons.group_outlined,
      title: 'Join an existing restaurant',
      subtitle:
          'Ask your manager for the Restaurant ID and invite code to join their team on Tavola.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthField(
              controller: _restaurantId,
              label: 'Restaurant ID',
              hint: 'e.g. TAV-48291',
            ),
            const SizedBox(height: TavolaSpace.md),
            _AuthField(
              controller: _inviteCode,
              label: 'Invite code',
              hint: '6-digit invite code',
            ),
            const SizedBox(height: TavolaSpace.md),
            _AuthField(
              controller: _email,
              label: 'Your work email',
              hint: 'you@restaurant.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            const SizedBox(height: TavolaSpace.md),
            _PrimaryButton(
              label: 'Request to Join',
              loading: state.isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                await ref
                    .read(authControllerProvider.notifier)
                    .redeemRestaurantInvitation(
                      restaurantCode: _restaurantId.text.trim(),
                      inviteCode: _inviteCode.text.trim(),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class StaffPinLoginPage extends ConsumerStatefulWidget {
  const StaffPinLoginPage({super.key});
  @override
  ConsumerState<StaffPinLoginPage> createState() => _StaffPinLoginPageState();
}

class _StaffPinLoginPageState extends ConsumerState<StaffPinLoginPage> {
  String _pin = '';
  String _selectedName = 'Anita Nair';
  String? _error;
  bool _verified = false;
  @override
  Widget build(BuildContext context) => _CenteredAuthCard(
    showMark: true,
    textAlign: TextAlign.center,
    title: 'Select your name',
    child: Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: TavolaSpace.md,
          children: [
            for (final staff in const [
              ('Rahul', 'RS'),
              ('Anita', 'AN'),
              ('Vikram', 'VK'),
            ])
              _StaffChoice(
                name: staff.$1,
                initials: staff.$2,
                selected: _selectedName.startsWith(staff.$1),
                onTap: () => setState(
                  () => _selectedName = staff.$1 == 'Anita'
                      ? 'Anita Nair'
                      : staff.$1,
                ),
              ),
          ],
        ),
        const SizedBox(height: TavolaSpace.lg),
        Text('Enter PIN for $_selectedName', style: _AuthText.body),
        const SizedBox(height: TavolaSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (i) => Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length
                    ? TavolaColors.accent
                    : TavolaColors.surface,
                border: Border.all(
                  color: i < _pin.length
                      ? TavolaColors.accent
                      : TavolaColors.borderStrong,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: TavolaSpace.lg),
        _PinKeypad(
          onDigit: (digit) => setState(() {
            if (_pin.length < 4) _pin += digit;
          }),
          onClear: () => setState(() => _pin = ''),
          onBackspace: () => setState(() {
            if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
          }),
        ),
        const SizedBox(height: TavolaSpace.lg),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: TavolaSpace.sm),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TavolaColors.error, fontSize: 13),
            ),
          ),
        if (_verified)
          const Text(
            'PIN verified for this signed-in account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TavolaColors.success, fontSize: 13),
          ),
        const SizedBox(height: TavolaSpace.sm),
        _PrimaryButton(
          label: 'Continue',
          loading: ref.watch(authControllerProvider).isLoading,
          onPressed: _verifyPin,
        ),
        const SizedBox(height: TavolaSpace.xs),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text('Back to Sign In'),
        ),
      ],
    ),
  );

  Future<void> _verifyPin() async {
    if (_pin.length != 4) {
      setState(() => _error = 'Enter your four-digit PIN.');
      return;
    }
    RestaurantMembership? membership;
    try {
      membership = await ref.read(currentMembershipProvider.future);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Sign in with email and password before using a PIN.',
        );
      }
      return;
    }
    if (!mounted) return;
    if (membership == null) {
      setState(
        () => _error = 'Sign in with email and password before using a PIN.',
      );
      return;
    }
    final valid = await ref
        .read(authControllerProvider.notifier)
        .verifyStaffPin(restaurantId: membership.restaurantId, pin: _pin);
    if (!mounted) return;
    setState(() {
      _verified = valid;
      _error = valid
          ? null
          : 'Incorrect PIN or PIN temporarily locked. Try again later.';
    });
  }
}

class _LoginLayout extends StatelessWidget {
  const _LoginLayout({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final form = Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(TavolaSpace.xl),
              child: SizedBox(width: 360, child: child),
            ),
          ),
        );
        if (constraints.maxWidth < TavolaBreakpoints.medium) {
          return Row(children: [form]);
        }
        return Row(
          children: [
            const Expanded(child: _BrandPanel()),
            form,
          ],
        );
      },
    ),
  );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();
  @override
  Widget build(BuildContext context) => Container(
    color: TavolaColors.primary,
    padding: const EdgeInsets.all(TavolaSpace.xxxl),
    child: Stack(
      children: [
        Positioned(
          right: -90,
          bottom: -90,
          child: Container(
            height: 260,
            width: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 44,
                color: TavolaColors.accent.withValues(alpha: .12),
              ),
            ),
          ),
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _Mark(),
                SizedBox(width: TavolaSpace.sm),
                Text('Tavola', style: _AuthText.brandName),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Every order, every table,', style: _AuthText.hero),
                Text('perfectly in sync.', style: _AuthText.heroAccent),
                SizedBox(height: TavolaSpace.sm),
                SizedBox(
                  width: 350,
                  child: Text(
                    'One system for order taking, kitchen tickets, table management, and billing — built for busy restaurants.',
                    style: _AuthText.heroCopy,
                  ),
                ),
              ],
            ),
            Text(
              '“Tavola cut our billing time in half during peak hours.”',
              style: _AuthText.quote,
            ),
          ],
        ),
      ],
    ),
  );
}

class _CenteredAuthCard extends StatelessWidget {
  const _CenteredAuthCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.backLabel,
    this.onBack,
    this.showMark = false,
    this.wide = false,
    this.textAlign = TextAlign.start,
  });

  final String title;
  final String? subtitle;
  final String? backLabel;
  final IconData? icon;
  final VoidCallback? onBack;
  final Widget child;
  final bool showMark;
  final bool wide;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TavolaColors.background,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TavolaSpace.lg),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: wide ? 520 : 400),
            padding: const EdgeInsets.all(TavolaSpace.xl),
            decoration: BoxDecoration(
              color: TavolaColors.surface,
              borderRadius: TavolaRadius.large,
              border: Border.all(color: TavolaColors.border),
              boxShadow: const [
                BoxShadow(
                  color: TavolaColors.shadow,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: textAlign == TextAlign.center
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (backLabel != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back,
                        size: TavolaSize.iconSmall,
                      ),
                      label: Text(backLabel!),
                    ),
                  ),
                if (showMark)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TavolaSpace.md),
                    child: textAlign == TextAlign.center
                        ? const _Mark()
                        : const Row(
                            children: [
                              _Mark(),
                              SizedBox(width: TavolaSpace.sm),
                              Text('Tavola', style: _AuthText.cardBrand),
                            ],
                          ),
                  ),
                if (icon != null)
                  Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.only(bottom: TavolaSpace.md),
                    decoration: const BoxDecoration(
                      color: TavolaColors.accentLight,
                      borderRadius: TavolaRadius.medium,
                    ),
                    child: Icon(icon, color: TavolaColors.accentDark),
                  ),
                Text(title, textAlign: textAlign, style: _AuthText.cardTitle),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: TavolaSpace.xs,
                      bottom: TavolaSpace.lg,
                    ),
                    child: Text(
                      subtitle!,
                      textAlign: textAlign,
                      style: _AuthText.body,
                    ),
                  )
                else
                  const SizedBox(height: TavolaSpace.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    validator:
        validator ??
        (value) => value == null || value.trim().isEmpty
            ? '$label is required.'
            : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffix,
    ),
  );
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: items
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: onChanged,
  );
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});
  final Widget first, second;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 440
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: first),
                const SizedBox(width: TavolaSpace.md),
                Expanded(child: second),
              ],
            )
          : Column(
              children: [
                first,
                const SizedBox(height: TavolaSpace.md),
                second,
              ],
            ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: TavolaSize.iconMedium,
              width: TavolaSize.iconMedium,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    ),
  );
}

class _FormDivider extends StatelessWidget {
  const _FormDivider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: TavolaSpace.lg),
    child: Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: TavolaSpace.sm),
          child: Text('or', style: _AuthText.muted),
        ),
        Expanded(child: Divider()),
      ],
    ),
  );
}

class _FooterText extends StatelessWidget {
  const _FooterText({
    required this.prefix,
    required this.label,
    required this.onPressed,
  });
  final String prefix, label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: _AuthText.muted,
      children: [
        TextSpan(text: prefix),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: TextButton(onPressed: onPressed, child: Text(label)),
        ),
      ],
    ),
  );
}

class _OnboardingDot extends StatelessWidget {
  const _OnboardingDot({this.active = false});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    width: active ? 18 : 7,
    height: 7,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      color: active ? TavolaColors.accent : TavolaColors.border,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

class _StaffChoice extends StatelessWidget {
  const _StaffChoice({
    required this.name,
    required this.initials,
    required this.selected,
    required this.onTap,
  });
  final String name, initials;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Select $name',
    child: InkWell(
      onTap: onTap,
      borderRadius: TavolaRadius.medium,
      child: Padding(
        padding: const EdgeInsets.all(TavolaSpace.xs),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: selected
                  ? TavolaColors.accent
                  : TavolaColors.secondary,
              child: Text(
                initials,
                style: const TextStyle(
                  color: TavolaColors.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: TavolaSpace.xs),
            Text(name, style: _AuthText.staffName),
          ],
        ),
      ),
    ),
  );
}

class _PinKeypad extends StatelessWidget {
  const _PinKeypad({
    required this.onDigit,
    required this.onClear,
    required this.onBackspace,
  });
  final ValueChanged<String> onDigit;
  final VoidCallback onClear, onBackspace;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    child: GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: TavolaSpace.sm,
      crossAxisSpacing: TavolaSpace.sm,
      childAspectRatio: 1.5,
      children: [
        ...List.generate(
          9,
          (i) => OutlinedButton(
            onPressed: () => onDigit('${i + 1}'),
            child: Text('${i + 1}', style: _AuthText.key),
          ),
        ),
        TextButton(onPressed: onClear, child: const Text('Clear')),
        OutlinedButton(
          onPressed: () => onDigit('0'),
          child: const Text('0', style: _AuthText.key),
        ),
        IconButton(
          tooltip: 'Delete PIN digit',
          onPressed: onBackspace,
          icon: const Icon(Icons.backspace_outlined),
        ),
      ],
    ),
  );
}

void _showAuthErrors(WidgetRef ref) {
  ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
    final error = next.error;
    if (error != null) {
      ScaffoldMessenger.of(
        ref.context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  });
}

String? _emailValidator(String? value) => value == null || !value.contains('@')
    ? 'Enter a valid email address.'
    : null;
String? _passwordValidator(String? value) =>
    value == null || value.length < 6 ? 'Use at least 6 characters.' : null;

class _Mark extends StatelessWidget {
  const _Mark({this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 38.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TavolaColors.accent,
        borderRadius: large ? TavolaRadius.large : TavolaRadius.medium,
      ),
      child: Text(
        'T',
        style: TextStyle(
          color: TavolaColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: large ? 30 : 18,
        ),
      ),
    );
  }
}

abstract final class _AuthText {
  static const splashTitle = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  static const splashCopy = TextStyle(
    color: TavolaColors.textMuted,
    fontSize: 14,
  );
  static const version = TextStyle(
    color: TavolaColors.textSecondary,
    fontSize: 11,
  );
  static const welcomeTitle = TextStyle(
    color: TavolaColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(
    color: TavolaColors.textSecondary,
    fontSize: 14,
    height: 1.6,
  );
  static const muted = TextStyle(color: TavolaColors.textMuted, fontSize: 13);
  static const checkbox = TextStyle(
    color: TavolaColors.textSecondary,
    fontSize: 13,
  );
  static const loginTitle = TextStyle(
    color: TavolaColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  static const cardTitle = TextStyle(
    color: TavolaColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const cardBrand = TextStyle(
    color: TavolaColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const brandName = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static const hero = TextStyle(
    color: Colors.white,
    fontSize: 30,
    fontWeight: FontWeight.w700,
  );
  static const heroAccent = TextStyle(
    color: TavolaColors.accent,
    fontSize: 30,
    fontWeight: FontWeight.w700,
  );
  static const heroCopy = TextStyle(
    color: TavolaColors.textMuted,
    fontSize: 14,
    height: 1.5,
  );
  static const quote = TextStyle(
    color: TavolaColors.textSecondary,
    fontSize: 12,
  );
  static const staffName = TextStyle(
    color: TavolaColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const key = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
}
