import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'skeleton_loading.dart';

/// Cached network image with skeleton loading placeholder.
class SpetoCachedImage extends StatelessWidget {
  const SpetoCachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.heroTag,
  });

  final String url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, imageUrl) => SkeletonLoading(
          width: width,
          height: height ?? 100,
          borderRadius: borderRadius,
        ),
        errorWidget: (context, imageUrl, error) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Palette.card,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: const Icon(Icons.broken_image_outlined, color: Palette.muted),
        ),
        memCacheWidth: width != null ? (width! * 2).toInt() : null,
        memCacheHeight: height != null ? (height! * 2).toInt() : null,
      ),
    );

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return image;
  }
}
