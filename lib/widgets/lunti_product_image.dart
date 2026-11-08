import 'package:flutter/material.dart';

import 'lunti_skeleton.dart';
import 'profile_photo.dart';

/// Product image that understands bundled asset paths (the existing catalog),
/// remote URLs, and inline base64 data URLs (photos added from the dashboard).
class LuntiProductImage extends StatelessWidget {
  const LuntiProductImage({
    super.key,
    required this.image,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.semanticLabel,
  });

  static const String fallbackAsset = 'assets/images/hero_craft.jpg';

  final String image;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? semanticLabel;

  bool get _isRemote =>
      image.startsWith('http://') || image.startsWith('https://');
  bool get _isEmbedded => image.startsWith('data:image/');

  @override
  Widget build(BuildContext context) {
    if (_isEmbedded) {
      final bytes = decodeBase64Image(image);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          semanticLabel: semanticLabel,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        );
      }
      return _fallback();
    }

    if (_isRemote) {
      return Image.network(
        image,
        fit: fit,
        width: width,
        height: height,
        semanticLabel: semanticLabel,
        errorBuilder: (context, error, stackTrace) => _fallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: width ?? 48,
              height: height ?? 48,
              child: const LuntiShimmer(
                child: SkeletonBox(
                  width: double.infinity,
                  height: double.infinity,
                  radius: 10,
                ),
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      image,
      fit: fit,
      width: width,
      height: height,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    return Image.asset(
      fallbackAsset,
      fit: fit,
      width: width,
      height: height,
      semanticLabel: semanticLabel,
    );
  }
}
