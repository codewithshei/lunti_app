import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../services/auth_service.dart';
import 'auth_widgets.dart';

/// Email/password sign-in form.
///
/// Used by [AuthScreen] for both the checkout gate and the protected Profile
/// tab. [onSignedIn] fires after Firebase accepts the credentials so the
/// caller can return to whatever the customer was doing (for example
/// Checkout) without losing the local bag.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onShowRegister,
    this.onBack,
    this.onSignedIn,
    this.onContinueAsGuest,
    this.title = 'Welcome back',
    this.subtitle =
        'Sign in to check out faster and follow your LUNTI orders.',
  });

  final VoidCallback onShowRegister;

  /// Optional back action; auth screens pushed on top of the shop use it.
  final VoidCallback? onBack;

  /// Called after a successful email/password sign-in.
  final VoidCallback? onSignedIn;

  /// When set, shows "Continue browsing as guest" under the form.
  final VoidCallback? onContinueAsGuest;

  final String title;
  final String subtitle;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      widget.onSignedIn?.call();
    } on FirebaseAuthException catch (exception) {
      if (!mounted) return;
      setState(() => _error = AuthService.friendlyMessage(exception));
    } catch (exception) {
      if (!mounted) return;
      setState(() => _error = 'Could not sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      onBack: widget.onBack,
      socialActions: const AuthGoogleButton(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthSwitchLink(
            prompt: 'New to LUNTI?',
            actionLabel: 'Create an account',
            onTap: widget.onShowRegister,
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
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _signIn(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: LuntiSpacing.xs),
              AuthPrimaryAction(
                label: 'Sign in',
                loading: _loading,
                onPressed: _signIn,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
