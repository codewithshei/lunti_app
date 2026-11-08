import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:admin_dashboard/theme.dart';

/// Decodes a `data:image/...;base64,...` value into bytes.
///
/// Product photos are stored inline on the `products` document (the Spark plan
/// has no Cloud Storage), matching the mobile profile-photo approach. Returns
/// null for asset paths, network URLs or malformed values, so callers can fall
/// back to another renderer.
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

/// Renders a product photo from an embedded base64 data URL, a network URL, or
/// a bundled asset path.
class AdminProductImage extends StatelessWidget {
  const AdminProductImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
  });

  final String image;
  final BoxFit fit;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final value = image.trim();
    if (value.isEmpty) return _fallback();

    final bytes = decodeBase64Image(value);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    final remote =
        value.startsWith('http://') || value.startsWith('https://');
    if (remote) {
      return Image.network(
        value,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    return Image.asset(
      value,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() => Icon(fallbackIcon, size: 18, color: AdminColors.muted);
}
