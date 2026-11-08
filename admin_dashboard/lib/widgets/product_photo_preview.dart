import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:admin_dashboard/services/product_image_service.dart';
import 'package:admin_dashboard/theme.dart';

/// Thumbnail, file name and size summary for a picked product photo.
///
/// Shows a subtle helper when the original file exceeds the 1MB upload limit.
class ProductPhotoPreview extends StatelessWidget {
  const ProductPhotoPreview({
    super.key,
    required this.bytes,
    required this.filename,
    required this.originalBytes,
    required this.preparedBytes,
    required this.wasCompressed,
  });

  final Uint8List bytes;
  final String filename;
  final int originalBytes;
  final int preparedBytes;
  final bool wasCompressed;

  @override
  Widget build(BuildContext context) {
    final exceedsLimit = originalBytes > ProductImageService.maxBytes;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AdminColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_outlined, size: 26),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                wasCompressed
                    ? '${formatBytes(originalBytes)} → ${formatBytes(preparedBytes)}'
                    : formatBytes(originalBytes),
                style: const TextStyle(color: AdminColors.muted, fontSize: 12),
              ),
              if (exceedsLimit) ...[
                const SizedBox(height: 6),
                const Text(
                  'Image exceeds 1MB — compressing automatically for fast app loading',
                  style: TextStyle(
                    color: AdminColors.info,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
