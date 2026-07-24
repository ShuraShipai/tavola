import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../providers/auth_providers.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Mark(),
          SizedBox(height: 16),
          Text(
            'Tavola',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: TavolaColors.accentLight,
                    borderRadius: BorderRadius.circular(72),
                  ),
                  child: const Icon(
                    Icons.soup_kitchen_outlined,
                    size: 84,
                    color: TavolaColors.accentDark,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Run your restaurant, front to back',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Take orders, manage tables, send tickets to the kitchen, and bill guests — all from one simple screen.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _OnboardingDot(active: true),
                    _OnboardingDot(),
                    _OnboardingDot(),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go(AppRoutes.registerRestaurant),
                    child: const Text('Get Started'),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('I already have an account — Log in'),
                ),
              ],
            ),
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
    return _AuthLayout(
      title: 'Welcome back',
      subtitle: 'Log in to your restaurant dashboard',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _emailField(_email),
            const SizedBox(height: 14),
            _passwordField(_password),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.forgotPassword),
                child: const Text('Forgot password?'),
              ),
            ),
            _SubmitButton(
              label: 'Sign In',
              loading: authState.isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                await ref
                    .read(authControllerProvider.notifier)
                    .signIn(email: _email.text, password: _password.text);
              },
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.registerRestaurant),
              child: const Text('Create a restaurant account'),
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
    return _AuthLayout(
      title: 'Forgot your password?',
      subtitle: _sent
          ? 'If an account exists for that address, a reset link is on its way.'
          : 'Enter your email and we will send a reset link.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _emailField(_email),
            const SizedBox(height: 20),
            _SubmitButton(
              label: 'Send reset link',
              loading: authState.isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                await ref
                    .read(authControllerProvider.notifier)
                    .sendPasswordReset(_email.text);
                if (mounted && !ref.read(authControllerProvider).hasError) {
                  setState(() => _sent = true);
                }
              },
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
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
  final _password = TextEditingController();

  @override
  void dispose() {
    _restaurant.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).dataOrNull;
    final authState = ref.watch(authControllerProvider);
    _showAuthErrors(ref);
    final creatingRestaurant = user != null;
    return _AuthLayout(
      title: creatingRestaurant
          ? 'Create your restaurant'
          : 'Create your restaurant account',
      subtitle: creatingRestaurant
          ? 'One last step before your Tavola workspace is ready.'
          : 'Set up Tavola for your restaurant in a few minutes.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _textField(_restaurant, 'Restaurant name'),
            if (!creatingRestaurant) ...[
              const SizedBox(height: 14),
              _textField(_name, 'Owner full name'),
              const SizedBox(height: 14),
              _emailField(_email),
              const SizedBox(height: 14),
              _passwordField(_password, label: 'Password'),
            ],
            const SizedBox(height: 20),
            _SubmitButton(
              label: creatingRestaurant
                  ? 'Create restaurant'
                  : 'Create account',
              loading: authState.isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);
                final controller = ref.read(authControllerProvider.notifier);
                if (creatingRestaurant) {
                  await controller.createRestaurant(name: _restaurant.text);
                } else {
                  await controller.signUp(
                    email: _email.text,
                    password: _password.text,
                    fullName: _name.text,
                  );
                  if (mounted && !ref.read(authControllerProvider).hasError) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Check your email to confirm your account, then sign in.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            if (!creatingRestaurant)
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('I already have an account'),
              ),
          ],
        ),
      ),
    );
  }
}

class JoinRestaurantPage extends StatelessWidget {
  const JoinRestaurantPage({super.key});

  @override
  Widget build(BuildContext context) => _AuthLayout(
    title: 'Join an existing restaurant',
    subtitle:
        'Your restaurant owner will add your account from Staff management.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sign in with the email address that your manager invited.'),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text('Sign in'),
        ),
      ],
    ),
  );
}

class StaffPinLoginPage extends StatelessWidget {
  const StaffPinLoginPage({super.key});

  @override
  Widget build(BuildContext context) => _AuthLayout(
    title: 'Staff PIN sign-in',
    subtitle: 'Staff PINs will be enabled with staff management in Phase 2.',
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => context.go(AppRoutes.login),
        child: const Text('Use email and password'),
      ),
    ),
  );
}

class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final form = Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: 390,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: TavolaColors.textSecondary,
                        fontSize: 14,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 24),
                    child,
                  ],
                ),
              ),
            ),
          ),
        );
        if (compact) return Row(children: [form]);
        return Row(
          children: [
            Expanded(
              child: Container(
                color: TavolaColors.primary,
                padding: const EdgeInsets.all(48),
                child: Stack(
                  children: [
                    Positioned(
                      right: -90,
                      bottom: -90,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x1FF59E0B),
                            width: 44,
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
                            SizedBox(width: 10),
                            Text(
                              'Tavola',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Every order, every table,',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'perfectly in sync.',
                              style: TextStyle(
                                color: TavolaColors.accent,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'One system for order taking, kitchen tickets, table management, and billing — built for busy restaurants.',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '“Tavola cut our billing time in half during peak hours.”',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            form,
          ],
        );
      },
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

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    ),
  );
}

TextFormField _emailField(TextEditingController controller) => _textField(
  controller,
  'Email address',
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value == null || !value.contains('@')
      ? 'Enter a valid email address.'
      : null,
);

TextFormField _passwordField(
  TextEditingController controller, {
  String label = 'Password',
}) => _textField(
  controller,
  label,
  obscureText: true,
  validator: (value) =>
      value == null || value.length < 6 ? 'Use at least 6 characters.' : null,
);

TextFormField _textField(
  TextEditingController controller,
  String label, {
  bool obscureText = false,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) => TextFormField(
  controller: controller,
  obscureText: obscureText,
  keyboardType: keyboardType,
  validator:
      validator ??
      (value) =>
          value == null || value.trim().isEmpty ? '$label is required.' : null,
  decoration: InputDecoration(labelText: label),
);

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

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: TavolaColors.accent,
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    child: SizedBox(
      width: 42,
      height: 42,
      child: Center(
        child: Text(
          'T',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: TavolaColors.primary,
          ),
        ),
      ),
    ),
  );
}
