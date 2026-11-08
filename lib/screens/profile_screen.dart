import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../data/mock_app_state.dart';
import '../services/database_service.dart';
import '../widgets/brand_header.dart';
import '../widgets/lunti_skeleton.dart';
import '../widgets/profile_photo.dart';
import 'edit_profile_screen.dart';
import 'saved_addresses_screen.dart';
import 'support_chat_screen.dart';

/// Profile tab.
///
/// The name, email and delivery address all come from the signed-in Firebase
/// account (`FirebaseAuth.instance.currentUser` and `users/{uid}`). Nothing is
/// hardcoded: a missing profile simply shows a neutral empty state, and the
/// address card opens [SavedAddressesScreen] to add or edit the real address.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onBack,
    required this.onViewOrders,
    required this.onViewWishlist,
    required this.onSignedOut,
    this.onOpenBag,
  });

  final VoidCallback onBack;
  final VoidCallback onViewOrders;
  final VoidCallback onViewWishlist;

  /// Returns the app to the Home tab after Firebase sign-out. The root screen
  /// rebuilds the Profile tab in guest mode from the auth stream.
  final VoidCallback onSignedOut;

  /// Opens the shopping bag in the shop flow. Null keeps the header bag icon
  /// informational instead of a dead button.
  final VoidCallback? onOpenBag;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Map<String, String> _emptyAddress = <String, String>{
    'street': '',
    'barangay': '',
    'city': '',
    'province': '',
    'postalCode': '',
    'phone': '',
  };

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

  String _text(Object? value) => value is String ? value.trim() : '';

  Future<void> _openAddresses() async {
    // Root stack on purpose: these account screens predate the Profile tab's
    // own navigator and keep their full-screen presentation.
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => SavedAddressesScreen(
          onBack: () => Navigator.of(routeContext).maybePop(),
        ),
      ),
    );
  }

  Future<void> _openEditProfile(
    User user,
    Map<String, String> address,
    String displayName,
    String phone,
    String photoUrl,
  ) async {
    await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditProfileScreen(
          user: user,
          initialName: displayName,
          initialPhone: phone,
          initialAddress: address,
          initialPhotoUrl: photoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Widget tests and offline previews build this screen without Firebase.
    if (Firebase.apps.isEmpty) {
      return _buildScreen(null, null, isLoadingProfile: false);
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) {
          return _buildScreen(null, null, isLoadingProfile: false);
        }
        return StreamBuilder<Map<String, dynamic>?>(
          stream: DatabaseService().getUser(user.uid),
          builder: (context, profileSnapshot) {
            final loading = profileSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !profileSnapshot.hasData;
            return _buildScreen(
              user,
              profileSnapshot.data,
              isLoadingProfile: loading,
              profileLoadFailed: profileSnapshot.hasError,
            );
          },
        );
      },
    );
  }

  Widget _buildScreen(
    User? user,
    Map<String, dynamic>? profile, {
    required bool isLoadingProfile,
    bool profileLoadFailed = false,
  }) {
    final address = _addressFromUser(profile);
    final profileName = _text(profile?['displayName']);
    final displayName = profileName.isNotEmpty
        ? profileName
        : (user?.displayName?.trim() ?? '');
    final phone = _text(profile?['phone']).isNotEmpty
        ? _text(profile?['phone'])
        : address['phone'] ?? '';
    final photoUrl = _text(profile?['photoUrl']).isNotEmpty
        ? _text(profile?['photoUrl'])
        : (user?.photoURL?.trim() ?? '');

    return Scaffold(
      backgroundColor: LuntiColors.cream,
      body: SafeArea(
        bottom: false,
        child: _ProfileBody(
          user: user,
          displayName: displayName,
          phone: phone,
          photoUrl: photoUrl,
          savedAddress: address,
          isLoadingAddress: isLoadingProfile,
          addressLoadFailed: profileLoadFailed,
          onEditProfile: user == null
              ? null
              : () => _openEditProfile(
                    user,
                    address,
                    displayName,
                    phone,
                    photoUrl,
                  ),
          onManageAddresses: _openAddresses,
          onOpenBag: widget.onOpenBag,
          onBack: widget.onBack,
          onViewOrders: widget.onViewOrders,
          onViewWishlist: widget.onViewWishlist,
          onSignedOut: widget.onSignedOut,
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.user,
    required this.displayName,
    required this.phone,
    required this.photoUrl,
    required this.savedAddress,
    required this.isLoadingAddress,
    required this.addressLoadFailed,
    this.onEditProfile,
    required this.onManageAddresses,
    this.onOpenBag,
    required this.onBack,
    required this.onViewOrders,
    required this.onViewWishlist,
    required this.onSignedOut,
  });

  final User? user;
  final String displayName;
  final String phone;
  final String photoUrl;
  final Map<String, String> savedAddress;
  final bool isLoadingAddress;
  final bool addressLoadFailed;
  final VoidCallback? onEditProfile;
  final VoidCallback onManageAddresses;
  final VoidCallback? onOpenBag;
  final VoidCallback onBack;
  final VoidCallback onViewOrders;
  final VoidCallback onViewWishlist;
  final VoidCallback onSignedOut;

  String get _name {
    final savedName = displayName.trim();
    if (savedName.isNotEmpty) return savedName;
    final authName = user?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;
    final email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'LUNTI customer';
  }

  String get _email {
    final email = user?.email?.trim();
    return email == null || email.isEmpty ? 'No email on file' : email;
  }

  String get _initials {
    final parts = _name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'L';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuntiColors.cream,
        title: const Text('Sign out?', style: LuntiTextStyles.sectionTitle),
        content: const Text(
          'Your bag and wishlist are saved to your account and will be here '
          'when you sign back in. Guest browsing starts with a clean bag.',
          style: LuntiTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not sign out. Please try again.'),
          backgroundColor: LuntiColors.forest,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Sign-out lands on the root Home tab in guest mode. It never opens the
    // login screen; signing in again is optional from Profile or Checkout.
    //
    // Do not gate this on this widget's context: the auth stream may already
    // have swapped the Profile tab to the guest prompt while signOut() was
    // awaiting. [onSignedOut] belongs to RootScreen, which stays mounted.
    onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BrandHeader(
          bagListenable: MockAppState.bagCount,
          onBack: onBack,
          onBagPressed: onOpenBag,
          showBadge: false,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(LuntiSpacing.gutter),
            children: [
              Text('Profile', style: LuntiTextStyles.display),
              const SizedBox(height: LuntiSpacing.xs),
              Text(
                'Your account, delivery details and saved pieces.',
                style: LuntiTextStyles.body,
              ),
              const SizedBox(height: LuntiSpacing.md),
              _ProfileHeaderCard(
                initials: _initials,
                name: _name,
                email: _email,
                phone: phone,
                photoUrl: photoUrl,
                isSignedIn: user != null,
                onEdit: onEditProfile,
              ),
              const SizedBox(height: LuntiSpacing.md),
              _AddressSummaryCard(
                isLoading: isLoadingAddress,
                loadFailed: addressLoadFailed,
                address: savedAddress,
                onManage: onManageAddresses,
              ),
              const SizedBox(height: LuntiSpacing.lg),
              Text('Account', style: LuntiTextStyles.sectionTitle),
              const SizedBox(height: LuntiSpacing.sm),
              if (onEditProfile != null) ...[
                _ProfileTile(
                  icon: Icons.person_outline,
                  title: 'Edit profile',
                  subtitle: 'Photo, name, phone and delivery address',
                  onTap: onEditProfile!,
                ),
                const SizedBox(height: LuntiSpacing.sm),
              ],
              _ProfileTile(
                icon: Icons.receipt_long_outlined,
                title: 'My orders',
                subtitle: 'Order history & live tracking',
                onTap: onViewOrders,
              ),
              const SizedBox(height: LuntiSpacing.sm),
              _ProfileTile(
                icon: Icons.favorite_border,
                title: 'Wishlist',
                subtitle: 'Saved pieces',
                onTap: onViewWishlist,
              ),
              const SizedBox(height: LuntiSpacing.sm),
              _ProfileTile(
                icon: Icons.support_agent,
                title: 'Chat with us',
                subtitle: 'Contact support about an order or engraving',
                onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => SupportChatScreen(uid: user?.uid),
                  ),
                ),
              ),
              if (user != null) ...[
                const SizedBox(height: LuntiSpacing.sm),
                _ProfileTile(
                  icon: Icons.logout,
                  title: 'Sign out',
                  subtitle: 'Sign out of this LUNTI account',
                  onTap: () => _signOut(context),
                ),
              ],
              const SizedBox(height: LuntiSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.isSignedIn,
    this.onEdit,
  });

  final String initials;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final bool isSignedIn;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.forest,
        borderRadius: BorderRadius.circular(LuntiRadii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileAvatar(initials: initials, photoUrl: photoUrl),
          const SizedBox(width: LuntiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: LuntiTextStyles.sectionTitle.copyWith(
                    color: LuntiColors.cream,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: LuntiTextStyles.caption.copyWith(
                    color: LuntiColors.sage,
                  ),
                ),
                if (phone.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: LuntiTextStyles.caption.copyWith(
                      color: LuntiColors.sage,
                    ),
                  ),
                ],
                const SizedBox(height: LuntiSpacing.xs),
                Text(
                  isSignedIn ? 'Signed in to LUNTI' : 'Browsing as a guest',
                  style: LuntiTextStyles.caption.copyWith(
                    color: LuntiColors.sage,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: LuntiColors.cream,
            ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials, required this.photoUrl});

  final String initials;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: LuntiColors.sage,
        shape: BoxShape.circle,
      ),
      child: ProfilePhotoImage(
        photoUrl: photoUrl,
        fallback: Center(
          child: Text(
            initials,
            style: LuntiTextStyles.cardTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressSummaryCard extends StatelessWidget {
  const _AddressSummaryCard({
    required this.isLoading,
    required this.loadFailed,
    required this.address,
    required this.onManage,
  });

  final bool isLoading;
  final bool loadFailed;
  final Map<String, String> address;
  final VoidCallback onManage;

  String get _fullAddress {
    final parts = [
      address['street'],
      address['barangay'],
      address['city'],
      address['province'],
      address['postalCode'],
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();
    return parts.join(', ');
  }

  bool get _hasAddress => _fullAddress.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuntiSpacing.md),
      decoration: BoxDecoration(
        color: LuntiColors.white,
        borderRadius: BorderRadius.circular(LuntiRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: LuntiColors.forest,
              ),
              const SizedBox(width: LuntiSpacing.xs),
              const Expanded(
                child: Text(
                  'Saved addresses',
                  style: LuntiTextStyles.cardTitle,
                ),
              ),
              TextButton(
                onPressed: onManage,
                child: Text(_hasAddress ? 'Manage' : 'Add'),
              ),
            ],
          ),
          const SizedBox(height: LuntiSpacing.xs),
          if (isLoading)
            const LuntiShimmer(
              child: SkeletonBox(width: 190, height: 12),
            )
          else if (loadFailed)
            Text(
              'Could not load your saved address.',
              style: LuntiTextStyles.body,
            )
          else if (!_hasAddress)
            Text(
              'No saved address yet. Add one to speed up checkout.',
              style: LuntiTextStyles.body,
            )
          else ...[
            Text('Home', style: LuntiTextStyles.cardTitle),
            const SizedBox(height: 2),
            Text(_fullAddress, style: LuntiTextStyles.body),
            if (address['phone']?.trim().isNotEmpty == true)
              Text(address['phone']!, style: LuntiTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LuntiColors.white,
      borderRadius: BorderRadius.circular(LuntiRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(LuntiRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(LuntiSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: LuntiColors.forest),
              const SizedBox(width: LuntiSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: LuntiTextStyles.cardTitle),
                    Text(subtitle, style: LuntiTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: LuntiColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
