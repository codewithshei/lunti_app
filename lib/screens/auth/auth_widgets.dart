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
      backgroundColor: LuntiColors.cream,
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
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: LuntiColors.forest,
                        ),
                        label: Text(
                          'Back',
                          style: LuntiTextStyles.caption.copyWith(
                            color: LuntiColors.forest,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: LuntiSpacing.xs),
                  ],
                  Text(
                    'LUNTI',
                    style: LuntiTextStyles.display.copyWith(
                      fontSize: 34,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: LuntiSpacing.xs),
                  const Text(
                    'Handcrafted bamboo, made personal.',
                    style: LuntiTextStyles.caption,
                  ),
                  const SizedBox(height: LuntiSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(LuntiSpacing.lg),
                    decoration: BoxDecoration(
                      color: LuntiColors.white,
                      borderRadius: BorderRadius.circular(LuntiRadii.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: LuntiTextStyles.sectionTitle.copyWith(
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle, style: LuntiTextStyles.body),
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
        style: LuntiTextStyles.body.copyWith(
          color: LuntiColors.ink,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperStyle: LuntiTextStyles.caption,
          filled: true,
          fillColor: LuntiColors.cream,
          labelStyle: LuntiTextStyles.body,
          hintStyle: LuntiTextStyles.caption,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LuntiSpacing.md,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
            borderSide: const BorderSide(color: LuntiColors.beige),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
            borderSide: const BorderSide(color: LuntiColors.beige),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
            borderSide: const BorderSide(color: LuntiColors.forest, width: 1.5),
          ),
          errorStyle: LuntiTextStyles.caption.copyWith(
            color: const Color(0xFF9B3D3D),
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
        color: const Color(0xFFF6E4E1),
        borderRadius: BorderRadius.circular(LuntiRadii.sm),
      ),
      child: Text(
        message,
        style: LuntiTextStyles.caption.copyWith(color: const Color(0xFF7E2F2F)),
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
          backgroundColor: LuntiColors.forest,
          foregroundColor: LuntiColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuntiRadii.sm),
          ),
        ),
        onPressed: null,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: LuntiColors.white,
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
          Text(prompt, style: LuntiTextStyles.caption),
          TextButton(
            onPressed: onTap,
            child: Text(
              actionLabel,
              style: LuntiTextStyles.cardTitle.copyWith(
                color: LuntiColors.forest,
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
        backgroundColor: LuntiColors.cream,
        title: const Text(
          'Google Sign-In is not connected yet',
          style: LuntiTextStyles.sectionTitle,
        ),
        content: const Text(
          'This prototype signs in with email and password. Google Sign-In '
          'needs OAuth client credentials from the project owner.',
          style: LuntiTextStyles.body,
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
      icon: const Icon(
        Icons.g_mobiledata,
        size: 26,
        color: LuntiColors.forest,
      ),
      label: Text(
        'Continue with Google',
        style: LuntiTextStyles.cardTitle.copyWith(
          color: LuntiColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: LuntiColors.cream,
        side: const BorderSide(color: LuntiColors.beige),
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
          style: LuntiTextStyles.cardTitle.copyWith(
            color: LuntiColors.secondary,
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
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: LuntiColors.secondary),
          const SizedBox(height: LuntiSpacing.sm),
          Text(
            title,
            style: LuntiTextStyles.sectionTitle.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(body, style: LuntiTextStyles.body, textAlign: TextAlign.center),
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

