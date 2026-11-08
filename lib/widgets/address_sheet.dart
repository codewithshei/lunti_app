import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'controls.dart';

/// Editable delivery-address bottom sheet shared by Checkout and Profile.
///
/// The sheet owns its text controllers so they are disposed with its own
/// lifecycle. Disposing them right after `showModalBottomSheet` resolves would
/// tear them down while the exit animation is still rebuilding the form.
///
/// It returns the trimmed address map through `Navigator.pop` once [onSave]
/// resolves, so the caller only needs to update its local state.
class AddressSheet extends StatefulWidget {
  const AddressSheet({
    super.key,
    required this.initialAddress,
    required this.canSync,
    required this.onSave,
    this.title = 'Delivery address',
    this.description = 'Used for this order and saved to your account.',
  });

  final Map<String, String> initialAddress;

  /// True when a signed-in user exists, so the address can sync to Firestore.
  final bool canSync;

  /// Persists the address. Throws on failure so the sheet can show an error.
  final Future<void> Function(Map<String, String> address) onSave;

  final String title;
  final String description;

  /// The required address keys, in display order.
  static const requiredKeys = <String>[
    'street',
    'barangay',
    'city',
    'province',
    'postalCode',
    'phone',
  ];

  @override
  State<AddressSheet> createState() => AddressSheetState();
}

class AddressSheetState extends State<AddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _street;
  late final TextEditingController _barangay;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _postalCode;
  late final TextEditingController _phone;

  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _street = TextEditingController(text: widget.initialAddress['street']);
    _barangay = TextEditingController(text: widget.initialAddress['barangay']);
    _city = TextEditingController(text: widget.initialAddress['city']);
    _province = TextEditingController(text: widget.initialAddress['province']);
    _postalCode =
        TextEditingController(text: widget.initialAddress['postalCode']);
    _phone = TextEditingController(text: widget.initialAddress['phone']);
  }

  @override
  void dispose() {
    _street.dispose();
    _barangay.dispose();
    _city.dispose();
    _province.dispose();
    _postalCode.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final address = <String, String>{
      'street': _street.text.trim(),
      'barangay': _barangay.text.trim(),
      'city': _city.text.trim(),
      'province': _province.text.trim(),
      'postalCode': _postalCode.text.trim(),
      'phone': _phone.text.trim(),
    };

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.onSave(address);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'Could not save your address. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(address);
  }

  String? _validatePostalCode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your postal code.';
    if (!RegExp(r'^\d{4}$').hasMatch(text)) {
      return 'Use a 4-digit postal code.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter a phone number.';
    if (!RegExp(r'^[0-9+\-\s()]{7,}$').hasMatch(text)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: LuntiSpacing.gutter,
        right: LuntiSpacing.gutter,
        top: LuntiSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + LuntiSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: LuntiSpacing.md),
                  decoration: BoxDecoration(
                    color: context.lunti.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.title,
                style: context.lunti.display.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(widget.description, style: context.lunti.body),
              const SizedBox(height: LuntiSpacing.md),
              _AddressField(
                controller: _street,
                label: 'Street address / House no.',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: LuntiSpacing.sm),
              _AddressField(
                controller: _barangay,
                label: 'Barangay',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: LuntiSpacing.sm),
              _AddressField(
                controller: _city,
                label: 'City / Municipality',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: LuntiSpacing.sm),
              _AddressField(
                controller: _province,
                label: 'Province',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: LuntiSpacing.sm),
              _AddressField(
                controller: _postalCode,
                label: 'Postal code',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _validatePostalCode,
              ),
              const SizedBox(height: LuntiSpacing.sm),
              _AddressField(
                controller: _phone,
                label: 'Phone number',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: _validatePhone,
              ),
              if (!widget.canSync) ...[
                const SizedBox(height: LuntiSpacing.sm),
                Text(
                  'Kept for this session only. Sign in to sync this '
                  'address to your account.',
                  style: context.lunti.caption.copyWith(
                    color: context.lunti.textFaint,
                  ),
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: LuntiSpacing.sm),
                Text(
                  _saveError!,
                  style: context.lunti.caption.copyWith(
                    color: Colors.red.shade700,
                  ),
                ),
              ],
              const SizedBox(height: LuntiSpacing.md),
              PrimaryButton(
                label: _isSaving ? 'Saving\u2026' : 'Save address',
                expand: true,
                onPressed: _isSaving ? null : _save,
              ),
              const SizedBox(height: LuntiSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: context.lunti.body.copyWith(color: context.lunti.text),
      decoration: InputDecoration(labelText: label),
      validator: validator ??
          (value) {
            if ((value ?? '').trim().isEmpty) return 'This field is required.';
            return null;
          },
    );
  }
}
