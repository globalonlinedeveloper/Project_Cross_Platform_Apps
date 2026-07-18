import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/e2e_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/providers.dart';
import '../shared/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _email =
      TextEditingController(text: 'alex@example.com');
  final TextEditingController _password =
      TextEditingController(text: 'password');
  bool _loading = false;
  bool _signUp = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final auth = ref.read(authRepositoryProvider);
    try {
      if (_signUp) {
        await auth.signUpWithEmail(
            email: _email.text.trim(), password: _password.text);
      } else {
        await auth.signInWithEmail(
            email: _email.text.trim(), password: _password.text);
      }
      if (mounted) context.go('/scan');
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apple() async {
    setState(() => _loading = true);
    final auth = ref.read(authRepositoryProvider);
    try {
      await auth.signInWithApple();
      if (mounted && auth.currentUser != null) context.go('/scan');
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('◈',
                    style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
              const SizedBox(height: 22),
              Text(_signUp ? 'Create account' : 'Welcome back',
                  style: AppText.title.copyWith(fontSize: 34)),
              const SizedBox(height: 6),
              Text(
                _signUp
                    ? 'Start tracking every subscription in one place.'
                    : 'Sign in to keep your money in check.',
                style: AppText.muted.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 28),
              _field('EMAIL', _email, TextInputType.emailAddress,
                  fieldKey: E2EKeys.loginEmail),
              const SizedBox(height: 14),
              _field('PASSWORD', _password, TextInputType.text,
                  obscure: true, fieldKey: E2EKeys.loginPassword),
              if (!_signUp)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await ref
                          .read(authRepositoryProvider)
                          .sendPasswordReset(_email.text.trim());
                      _snack('Password reset sent (demo).');
                    },
                    child: Text('Forgot password?',
                        style: AppText.body.copyWith(
                            color: AppColors.accent, fontWeight: FontWeight.w700)),
                  ),
                ),
              const SizedBox(height: 12),
              GradientButton(
                key: E2EKeys.loginSubmit,
                label: _loading
                    ? 'Please wait…'
                    : (_signUp ? 'Create account' : 'Sign in'),
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 20),
              Row(
                children: const <Widget>[
                  Expanded(child: Divider(color: AppColors.line)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: AppColors.muted)),
                  ),
                  Expanded(child: Divider(color: AppColors.line)),
                ],
              ),
              const SizedBox(height: 20),
              SoftButton(
                label: '  Continue with Apple',
                onPressed: _loading ? null : _apple,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _signUp = !_signUp),
                  child: Text.rich(
                    TextSpan(
                      text: _signUp ? 'Have an account? ' : 'New here? ',
                      style: AppText.muted.copyWith(fontSize: 14),
                      children: <InlineSpan>[
                        TextSpan(
                          text: _signUp ? 'Sign in' : 'Create account',
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Center(child: PoweredByNikatru()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, TextInputType type,
      {bool obscure = false, Key? fieldKey}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppText.label),
        const SizedBox(height: 7),
        TextField(
          key: fieldKey,
          controller: c,
          obscureText: obscure,
          keyboardType: type,
          style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
