import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../services/auth_service.dart';
import 'auth_widgets.dart';

/// Account creation form shared by the checkout gate and the Profile tab.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onShowLogin,
    this.onBack,
    this.onSignedIn,
    this.onContinueAsGuest,
  });

  final VoidCallback onShowLogin;

  /// Optional back action; auth screens pushed on top of the shop use it.
  final VoidCallback? onBack;

  /// Called after the account is created and the display name is stored.
  final VoidCallback? onSignedIn;

  /// When set, shows "Continue browsing as guest" under the form.
  final VoidCallback? onContinueAsGuest;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        await credential.user?.updateDisplayName(name);
      }
      widget.onSignedIn?.call();
    } on FirebaseAuthException catch (exception) {
      if (!mounted) return;
      setState(() => _error = AuthService.friendlyMessage(exception));
    } catch (exception) {
      if (!mounted) return;
      setState(() => _error = 'Could not create your account. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'A few details and your LUNTI bag is ready to fill.',
      onBack: widget.onBack,
      socialActions: const AuthGoogleButton(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthSwitchLink(
            prompt: 'Already have an account?',
            actionLabel: 'Sign in',
            onTap: widget.onShowLogin,
          ),
          if (widget.onContinueAsGuest != null)
            AuthGuestAction(onTap: widget.onContinueAsGuest!),
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              if (_error != null) AuthErrorBanner(message: _error!),
              AuthField(
                controller: _nameController,
                label: 'Full name',
                hint: 'Your full name',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if ((value?.trim() ?? '').isEmpty) {
                    return 'Enter your name.';
                  }
                  return null;
                },
              ),
              AuthField(
                controller: _emailController,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Enter your email address.';
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              AuthField(
                controller: _passwordController,
                label: 'Password',
                helper: 'At least 6 characters',
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Use at least 6 characters.';
                  }
                  return null;
                },
              ),
              AuthField(
                controller: _confirmController,
                label: 'Confirm password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _register(),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: LuntiSpacing.xs),
              AuthPrimaryAction(
                label: 'Create account',
                loading: _loading,
                onPressed: _register,
              ),
              const SizedBox(height: LuntiSpacing.xs),
              Text(
                'Prototype account. Never enter real payment details.',
                style: context.lunti.caption.copyWith(
                  color: context.lunti.textFaint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
