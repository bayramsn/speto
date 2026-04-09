import 'package:flutter/material.dart';

import 'speto_shimmer.dart';

class SpetoNetworkImage extends StatelessWidget {
  const SpetoNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder:
          (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: width,
              height: height,
              child: const SpetoShimmer(),
            );
          },
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return Container(
              width: width,
              height: height,
              color: Theme.of(context).cardColor,
              child: const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.grey),
              ),
            );
          },
    );
  }
}
