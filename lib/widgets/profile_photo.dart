import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Decodes a `data:image/...;base64,...` value into bytes.
///
/// The project is on the Firebase Spark plan, so photos (profile pictures and
/// admin-added product photos) are stored inline as base64 data URLs in
/// Firestore instead of being uploaded to Cloud Storage. Returns null for
/// regular network URLs or malformed values, so callers can fall back to
/// `Image.network`.
Uint8List? decodeBase64Image(String value) {
  const marker = 'base64,';
  final index = value.indexOf(marker);
  if (index < 0) return null;
  final payload = value.substring(index + marker.length);
  if (payload.isEmpty) return null;
  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

/// Decodes a profile photo. Kept for the existing profile-screen callers.
Uint8List? decodeProfilePhoto(String value) => decodeBase64Image(value);

/// Renders a profile photo from either a base64 data URL stored in Firestore
/// or a regular network image URL.
///
/// [fallback] is shown when the value is empty or the image fails to load
/// (for example the initials avatar).
class ProfilePhotoImage extends StatelessWidget {
  const ProfilePhotoImage({
    super.key,
    required this.photoUrl,
    required this.fallback,
  });

  final String photoUrl;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl.trim();
    if (url.isEmpty) return fallback;

    final bytes = decodeProfilePhoto(url);
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
