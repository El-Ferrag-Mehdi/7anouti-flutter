import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/auth/view/register_page.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/buttons.dart' as app_buttons;
import 'package:sevenouti/core/widgets/cards.dart';
import 'package:sevenouti/core/widgets/language_selector_tile.dart';
import 'package:sevenouti/l10n/l10n.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('Trying login with ${_emailController.text}');

      await context.read<AuthCubit>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      debugPrint('LOGIN SUCCESS');
    } on Object catch (e, stack) {
      debugPrint('LOGIN FAILED');
      debugPrint(e.toString());
      debugPrint(stack.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  Center(
                    child: Image.asset(
                      'assets/logo/logo_full.png',
                      height: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    l10n.authWelcomeTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.authWelcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.authLoginTitle,
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const LanguageSelectorTile(),
                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.authEmailLabel,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.authEmailRequired;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n.authPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return l10n.authPasswordInvalid;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        app_buttons.PrimaryButton(
                          label: l10n.authLoginButton,
                          icon: Icons.login,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _onLogin,
                          fullWidth: true,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        TextButton(
                          onPressed: () {
                            unawaited(
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const RegisterPage(),
                                ),
                              ),
                            );
                          },
                          child: Text(l10n.authCreateAccount),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
