import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../services/database_service.dart';
import '../widgets/address_sheet.dart';
import '../widgets/brand_header.dart';
import '../widgets/controls.dart';
import '../widgets/lunti_skeleton.dart';

/// Saved delivery address for the signed-in customer.
///
/// Everything on this screen comes from the live `users/{uid}` document; there
/// is no sample name or address. The account currently stores one delivery
/// address, so the screen shows that address (or a clean empty state) and lets
/// the customer add or edit it through the shared [AddressSheet].
class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  static const Map<String, String> _emptyAddress = <String, String>{
    'street': '',
    'barangay': '',
    'city': '',
    'province': '',
    'postalCode': '',
    'phone': '',
  };

  int _reloadToken = 0;

  String? get _userId {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Map<String, String> _addressFromUser(Map<String, dynamic>? data) {
    if (data == null) return _emptyAddress;
    final rawAddress = data['address'];
    final address = rawAddress is Map ? rawAddress : const <String, dynamic>{};

    String pick(String key) {
      final fromAddress = address[key];
      if (fromAddress is String && fromAddress.trim().isNotEmpty) {
        return fromAddress.trim();
      }
      final fromRoot = data[key];
      if (fromRoot is String && fromRoot.trim().isNotEmpty) {
        return fromRoot.trim();
      }
      return '';
    }

    return <String, String>{
      'street': pick('street'),
      'barangay': pick('barangay'),
      'city': pick('city'),
      'province': pick('province'),
      'postalCode': pick('postalCode'),
      'phone': pick('phone'),
    };
  }

  bool _hasAddress(Map<String, String> address) {
    const addressKeys = [
      'street',
      'barangay',
      'city',
      'province',
      'postalCode',
    ];
    return addressKeys.any(
      (key) => (address[key] ?? '').trim().isNotEmpty,
    );
  }

  Future<void> _editAddress(Map<String, String> current) async {
    final userId = _userId;
    if (userId == null) {
      _showMessage('Sign in to save a delivery address.');
      return;
    }

    final saved = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.lunti.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LuntiRadii.lg)),
      ),
      builder: (sheetContext) => AddressSheet(
        initialAddress: current,
        canSync: true,
        title: _hasAddress(current) ? 'Edit address' : 'Add address',
        description: 'Saved to your LUNTI account for future orders.',
        onSave: (address) =>
            DatabaseService().saveUserAddress(userId, address),
      ),
    );

    if (saved == null || !mounted) return;
    _showMessage('Delivery address saved.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      backgroundColor: context.lunti.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrandHeader(
              onBack: widget.onBack,
              onBagPressed: null,
              showBadge: false,
            ),
            Expanded(
              child: userId == null
                  ? _content(
                      const _SignedOutState(),
                    )
                  : StreamBuilder<Map<String, dynamic>?>(
                      key: ValueKey<int>(_reloadToken),
                      stream: DatabaseService().getUser(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return _content(const _AddressLoading());
                        }
                        if (snapshot.hasError) {
                          return _content(
                            _AddressError(
                              onRetry: () => setState(() => _reloadToken++),
                            ),
                          );
                        }
                        final address = _addressFromUser(snapshot.data);
                        if (!_hasAddress(address)) {
                          return _content(
                            _EmptyAddressState(
                              onAdd: () => _editAddress(address),
                            ),
                          );
                        }
                        return _content(
                          _AddressCard(
                            address: address,
                            onEdit: () => _editAddress(address),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(Widget child) {
    return ListView(
      padding: const EdgeInsets.all(LuntiSpacing.gutter),
      children: [
        Text('Saved addresses', style: context.lunti.display),
        const SizedBox(height: LuntiSpacing.xs),
        Text(
          'Your delivery details are filled in automatically at checkout.',
          style: context.lunti.body,
        ),
        const SizedBox(height: LuntiSpacing.md),
        child,
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onEdit});

  final Map<String, String> address;
  final VoidCallback onEdit;

  String get _street => address['street']?.trim() ?? '';

  String get _locality {
    final parts = [
      address['barangay'],
      address['city'],
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();
    return parts.join(', ');
  }

  String get _region {
    final parts = [
      address['province'],
      address['postalCode'],
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final lines = [
      _street,
      _locality,
      _region,
    ].where((line) => line.trim().isNotEmpty).toList();
    final phone = address['phone']?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: context.lunti.surface,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.lunti.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_filled,
                  size: 18,
                  color: context.lunti.accent,
                  semanticLabel: 'Delivery address',
                ),
              ),
              const SizedBox(width: LuntiSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Home', style: context.lunti.cardTitle),
                    Text(
                      'Default delivery address',
                      style: context.lunti.caption,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: LuntiSpacing.sm),
          for (final line in lines) ...[
            Text(line, style: context.lunti.body),
            const SizedBox(height: 2),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: LuntiSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: context.lunti.textFaint,
                ),
                const SizedBox(width: 6),
                Text(phone, style: context.lunti.body),
              ],
            ),
          ],
          const SizedBox(height: LuntiSpacing.md),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit address'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.lunti.accent,
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: context.lunti.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LuntiRadii.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  const _EmptyAddressState({required this.onAdd});

  final VoidCallback onAdd;

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
          Icon(
            Icons.location_on_outlined,
            size: 40,
            color: context.lunti.textFaint,
          ),
          const SizedBox(height: LuntiSpacing.sm),
          Text(
            'No saved address yet',
            style: context.lunti.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            'Add your delivery details once and LUNTI will use them at '
            'checkout.',
            style: context.lunti.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuntiSpacing.md),
          PrimaryButton(
            label: 'Add address',
            expand: true,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

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
          Icon(
            Icons.lock_outline,
            size: 40,
            color: context.lunti.textFaint,
          ),
          const SizedBox(height: LuntiSpacing.sm),
          Text(
            'Sign in to save an address',
            style: context.lunti.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            'Your delivery details are stored with your LUNTI account.',
            style: context.lunti.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AddressLoading extends StatelessWidget {
  const _AddressLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: context.lunti.surface,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: const LuntiShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 96, height: 13),
            SizedBox(height: 10),
            SkeletonBox(width: double.infinity, height: 12),
            SizedBox(height: 6),
            SkeletonBox(width: 220, height: 12),
          ],
        ),
      ),
    );
  }
}

class _AddressError extends StatelessWidget {
  const _AddressError({required this.onRetry});

  final VoidCallback onRetry;

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
          Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: context.lunti.textFaint,
          ),
          const SizedBox(height: LuntiSpacing.sm),
          Text(
            'Could not load your address',
            style: context.lunti.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuntiSpacing.xs),
          Text(
            'Check your connection and try again.',
            style: context.lunti.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuntiSpacing.md),
          PrimaryButton(label: 'Try again', expand: true, onPressed: onRetry),
        ],
      ),
    );
  }
}
