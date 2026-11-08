import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../widgets/controls.dart';

/// Shared LUNTI presentation for the login and registration screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.onBack,
    this.socialActions,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;

  /// Optional back action for auth screens pushed from the shopping flow.
  final VoidCallback? onBack;

  /// Optional alternative sign-in methods (for example Google) shown between
  /// the intro copy and the email/password form.
  final Widget? socialActions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lunti.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: LuntiSpacing.gutter,
              vertical: LuntiSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onBack != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onBack,
                        icon: Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: context.lunti.accent,
                        ),
                        label: Text(
                          'Back',
                          style: context.lunti.caption.copyWith(
                            color: context.lunti.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: LuntiSpacing.xs),
                  ],
                  Text(
                    'LUNTI',
                    style: context.lunti.display.copyWith(
                      fontSize: 34,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: LuntiSpacing.xs),
                  Text(
                    'Handcrafted bamboo, made personal.',
                    style: context.lunti.caption,
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(LuntiSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.lunti.surface,
                      borderRadius: BorderRadius.circular(LuntiRadii.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.lunti.sectionTitle.copyWith(
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle, style: context.lunti.body),
                        const SizedBox(height: LuntiSpacing.md),
                        if (socialActions != null) ...[
                          socialActions!,
                          const SizedBox(height: LuntiSpacing.md),
                        ],
                        ...children,
                      ],
                    ),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: LuntiSpacing.md),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LuntiSpacing.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        style: context.lunti.body.copyWith(
          color: context.lunti.text,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperStyle: context.lunti.caption,
          filled: true,
          fillColor: context.lunti.background,
          labelStyle: context.lunti.body,
          hintStyle: context.lunti.caption,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LuntiSpacing.md,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
            borderSide: BorderSide(color: context.lunti.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
            borderSide: BorderSide(color: context.lunti.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
            borderSide: BorderSide(color: context.lunti.accent, width: 1.5),
          ),
          errorStyle: context.lunti.caption.copyWith(
            color: context.lunti.warning,
          ),
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: LuntiSpacing.sm),
      padding: const EdgeInsets.all(LuntiSpacing.sm),
      decoration: BoxDecoration(
        color: context.lunti.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(LuntiRadii.sm),
      ),
      child: Text(
        message,
        style: context.lunti.caption.copyWith(color: context.lunti.warning),
      ),
    );
  }
}

class AuthPrimaryAction extends StatelessWidget {
  const AuthPrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: context.lunti.accent,
          foregroundColor: context.lunti.surface,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
          ),
        ),
        onPressed: null,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.lunti.surface,
          ),
        ),
      );
    }
    return PrimaryButton(
      label: label,
      expand: true,
      onPressed: onPressed,
    );
  }
}

class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(prompt, style: context.lunti.caption),
          TextButton(
            onPressed: onTap,
            child: Text(
              actionLabel,
              style: context.lunti.cardTitle.copyWith(
                color: context.lunti.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Google sign-in entry point.
///
/// The prototype has no OAuth client configured, so this button is explicit
/// about that instead of pretending a real Google account was connected.
/// Email/password remains the working path until the project owner supplies
/// Google OAuth credentials.
class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({super.key});

  Future<void> _showNotice(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.lunti.background,
        title: Text(
          'Google Sign-In is not connected yet',
          style: context.lunti.sectionTitle,
        ),
        content: Text(
          'This prototype signs in with email and password. Google Sign-In '
          'needs OAuth client credentials from the project owner.',
          style: context.lunti.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showNotice(context),
      icon: Icon(
        Icons.g_mobiledata,
        size: 26,
        color: context.lunti.accent,
      ),
      label: Text(
        'Continue with Google',
        style: context.lunti.cardTitle.copyWith(
          color: context.lunti.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: context.lunti.background,
        side: BorderSide(color: context.lunti.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuntiRadii.sm),
        ),
      ),
    );
  }
}

/// Secondary action that closes an auth gate and keeps the guest shopping.
class AuthGuestAction extends StatelessWidget {
  const AuthGuestAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Text(
          'Continue browsing as guest',
          style: context.lunti.cardTitle.copyWith(
            color: context.lunti.textFaint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Friendly panel shown when a guest opens a screen that needs an account.
class AuthRequiredCard extends StatelessWidget {
  const AuthRequiredCard({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onPressed,
    this.icon = Icons.lock_outline,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.lg),
      decoration: BoxDecoration(
        color: context.lunti.surface,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: context.lunti.textFaint),
          const SizedBox(height: LuntiSpacing.sm),
          Text(
            title,
            style: context.lunti.sectionTitle.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(body, style: context.lunti.body, textAlign: TextAlign.center),
          const SizedBox(height: LuntiSpacing.md),
          PrimaryButton(
            label: actionLabel,
            expand: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

