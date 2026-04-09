import 'package:flutter/material.dart';

import 'speto_network_image.dart';

class SpetoImage extends StatelessWidget {
  const SpetoImage({
    super.key,
    required this.url,
    required this.height,
    this.borderRadius = 24,
    this.overlay,
    this.fit = BoxFit.cover,
    this.heroTag,
  });

  final String url;
  final double height;
  final double borderRadius;
  final Widget? overlay;
  final BoxFit fit;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: <Widget>[
          SpetoNetworkImage(
            url: url,
            height: height,
            width: double.infinity,
            fit: fit,
          ),
          if (overlay != null) Positioned.fill(child: overlay!),
        ],
      ),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: imageWidget);
    }
    return imageWidget;
  }
}
