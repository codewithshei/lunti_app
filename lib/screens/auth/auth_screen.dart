import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

/// Sign-in / create-account flow used as an auth gate on top of the shop.
///
/// It is pushed with `Navigator.push<bool>` and pops with:
/// * `true`  — the customer signed in or created an account
/// * `false` — the customer chose "Continue browsing as guest"
/// * `null`  — the customer backed out without choosing
///
/// The local guest bag lives in `MockAppState`, so it is untouched by this
/// screen and is still there when Checkout opens.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.title,
    this.subtitle,
    this.allowContinueAsGuest = false,
  });

  /// Checkout overrides this with "Sign in to check out".
  final String? title;

  final String? subtitle;

  /// Shows the "Continue browsing as guest" action when true.
  final bool allowContinueAsGuest;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showRegister = false;

  void _complete() {
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _continueAsGuest() {
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  void _back() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (_showRegister) {
      return RegisterScreen(
        onShowLogin: () => setState(() => _showRegister = false),
        onBack: _back,
        onSignedIn: _complete,
        onContinueAsGuest:
            widget.allowContinueAsGuest ? _continueAsGuest : null,
      );
    }

    return LoginScreen(
      onShowRegister: () => setState(() => _showRegister = true),
      onBack: _back,
      onSignedIn: _complete,
      onContinueAsGuest:
          widget.allowContinueAsGuest ? _continueAsGuest : null,
      title: widget.title ?? 'Welcome back',
      subtitle: widget.subtitle ??
          'Sign in to check out faster and follow your LUNTI orders.',
    );
  }
}
