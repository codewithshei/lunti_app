import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_theme.dart';
import '../services/database_service.dart';
import '../widgets/brand_header.dart';
import '../widgets/controls.dart';
import '../widgets/profile_photo.dart';

/// Lets a signed-in customer change their photo, display name, phone number and
/// delivery address. The account email is shown read-only because it belongs to
/// the Firebase Auth account and cannot be edited here.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.user,
    required this.initialName,
    required this.initialPhone,
    required this.initialAddress,
    required this.initialPhotoUrl,
  });

  final User user;
  final String initialName;
  final String initialPhone;
  final Map<String, String> initialAddress;
  final String initialPhotoUrl;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Firestore documents cap at 1 MiB and base64 inflates the bytes by ~33%,
  // so the photo must stay small enough to fit on the user document.
  static const int _maxPhotoBytes = 256 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _street;
  late final TextEditingController _barangay;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _postalCode;

  Uint8List? _pickedBytes;
  String? _pickedFileName;
  late String _photoUrl;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _phone = TextEditingController(text: widget.initialPhone);
    _street = TextEditingController(text: widget.initialAddress['street']);
    _barangay = TextEditingController(text: widget.initialAddress['barangay']);
    _city = TextEditingController(text: widget.initialAddress['city']);
    _province = TextEditingController(text: widget.initialAddress['province']);
    _postalCode =
        TextEditingController(text: widget.initialAddress['postalCode']);
    _photoUrl = widget.initialPhotoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _street.dispose();
    _barangay.dispose();
    _city.dispose();
    _province.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  String get _initials {
    final parts =
        _name.text.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'L';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  bool get _hasPhoto => _pickedBytes != null || _photoUrl.isNotEmpty;

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (!mounted) return;
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxPhotoBytes) {
        setState(
          () => _saveError = 'Choose an image smaller than 256 KB.',
        );
        return;
      }
      setState(() {
        _pickedBytes = bytes;
        _pickedFileName = picked.name;
        _saveError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saveError = 'Could not open your photo picker.');
      debugPrint('Could not pick a profile photo: $error');
    }
  }

  void _removePhoto() {
    setState(() {
      _pickedBytes = null;
      _pickedFileName = null;
      _photoUrl = '';
      _saveError = null;
    });
  }

  String get _photoContentType {
    final name = _pickedFileName?.toLowerCase() ?? '';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Encodes the picked photo as a base64 data URL for the user document.
  ///
  /// Cloud Storage is not used: the project is on the Firebase Spark plan, so
  /// the photo travels inline on `users/{uid}.photoUrl` instead.
  String _encodePhoto() {
    final bytes = _pickedBytes;
    if (bytes == null) return _photoUrl;
    return 'data:$_photoContentType;base64,${base64Encode(bytes)}';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final address = <String, String>{
      'street': _street.text.trim(),
      'barangay': _barangay.text.trim(),
      'city': _city.text.trim(),
      'province': _province.text.trim(),
      'postalCode': _postalCode.text.trim(),
      'phone': phone,
    };

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final photoUrl = _encodePhoto();

      // Keep the Firebase Auth profile in step where possible. Firestore is the
      // source of truth for the editable fields, so a failed Auth update must
      // not discard the customer's edits.
      try {
        await widget.user.updateDisplayName(name);
      } catch (error) {
        debugPrint('Could not update the auth display name: $error');
      }
      // The Auth photoURL must stay a fetchable URL, so a base64 data URL is
      // never written there. It is only cleared when the customer removes
      // their photo, so the profile falls back to initials.
      if (photoUrl.isEmpty && widget.user.photoURL != null) {
        try {
          await widget.user.updatePhotoURL(null);
        } catch (error) {
          debugPrint('Could not clear the auth photo URL: $error');
        }
      }

      await DatabaseService().updateUserProfile(
        uid: widget.user.uid,
        displayName: name,
        phone: phone,
        photoUrl: photoUrl,
        address: address,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError =
            'Could not save your profile. Check your connection and try again.';
      });
      debugPrint('Could not save the profile: $error');
    }
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your display name.';
    if (text.length > 60) return 'Keep your name under 60 characters.';
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^[0-9+\-\s()]{7,}$').hasMatch(text)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  String? _validatePostalCode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^\d{4}$').hasMatch(text)) {
      return 'Use a 4-digit postal code.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lunti.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrandHeader(
              onBack: () => Navigator.of(context).maybePop(),
              onBagPressed: null,
              showBadge: false,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(LuntiSpacing.gutter),
                  children: [
                    Text('Edit profile', style: context.lunti.display),
                    const SizedBox(height: LuntiSpacing.xs),
                    Text(
                      'Update the details saved to your LUNTI account.',
                      style: context.lunti.body,
                    ),
                    const SizedBox(height: LuntiSpacing.lg),
                    Center(child: _buildAvatar()),
                    const SizedBox(height: LuntiSpacing.sm),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: LuntiSpacing.xs,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : _pickPhoto,
                            icon: const Icon(Icons.photo_camera_outlined, size: 18),
                            label: Text(
                              _hasPhoto ? 'Change photo' : 'Upload photo',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.lunti.accent,
                              minimumSize: const Size(0, 44),
                              side: BorderSide(color: context.lunti.border),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(LuntiRadii.sm),
                              ),
                            ),
                          ),
                          if (_hasPhoto)
                            TextButton(
                              onPressed: _isSaving ? null : _removePhoto,
                              child: const Text('Remove'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: LuntiSpacing.lg),
                    _SectionLabel('Personal details'),
                    const SizedBox(height: LuntiSpacing.sm),
                    _ProfileField(
                      controller: _name,
                      label: 'Display name',
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                    ),
                    const SizedBox(height: LuntiSpacing.sm),
                    TextFormField(
                      initialValue: widget.user.email ?? 'No email on file',
                      readOnly: true,
                      style: context.lunti.body.copyWith(
                        color: context.lunti.textFaint,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        helperText: 'Your sign-in email cannot be changed here.',
                        suffixIcon: Icon(Icons.lock_outline, size: 18),
                      ),
                    ),
                    const SizedBox(height: LuntiSpacing.sm),
                    _ProfileField(
                      controller: _phone,
                      label: 'Phone number',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: LuntiSpacing.lg),
                    _SectionLabel('Delivery address'),
                    const SizedBox(height: LuntiSpacing.xs),
                    Text(
                      'Leave the address blank to clear it from your account.',
                      style: context.lunti.caption,
                    ),
                    const SizedBox(height: LuntiSpacing.sm),
                    _ProfileField(
                      controller: _street,
                      label: 'Street address / House no.',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: LuntiSpacing.sm),
                    _ProfileField(
                      controller: _barangay,
                      label: 'Barangay',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: LuntiSpacing.sm),
                    _ProfileField(
                      controller: _city,
                      label: 'City / Municipality',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: LuntiSpacing.sm),
                    _ProfileField(
                      controller: _province,
                      label: 'Province',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: LuntiSpacing.sm),
                    _ProfileField(
                      controller: _postalCode,
                      label: 'Postal code',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: _validatePostalCode,
                    ),
                    if (_saveError != null) ...[
                      const SizedBox(height: LuntiSpacing.sm),
                      Text(
                        _saveError!,
                        style: context.lunti.caption.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: LuntiSpacing.lg),
                    PrimaryButton(
                      label: _isSaving ? 'Saving\u2026' : 'Save changes',
                      expand: true,
                      onPressed: _isSaving ? null : _save,
                    ),
                    const SizedBox(height: LuntiSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 92,
          height: 92,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.lunti.surfaceAlt,
            shape: BoxShape.circle,
          ),
          child: _avatarContent(),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.lunti.accent,
              shape: BoxShape.circle,
              border: Border.all(color: context.lunti.background, width: 2),
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: 16,
              color: context.lunti.background,
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarContent() {
    if (_pickedBytes != null) {
      return Image.memory(_pickedBytes!, fit: BoxFit.cover);
    }
    return ProfilePhotoImage(
      photoUrl: _photoUrl,
      fallback: _initialsAvatar(),
    );
  }

  Widget _initialsAvatar() {
    return Center(
      child: Text(
        _initials,
        style: context.lunti.sectionTitle.copyWith(
          color: context.lunti.accent,
          fontSize: 26,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: context.lunti.sectionTitle);
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
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
      validator: validator,
    );
  }
}
