import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

class SpetoCard extends StatelessWidget {
  const SpetoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Palette.card,
    this.radius = 24,
    this.borderColor,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final Color? borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool useDefaultCardColor = color == Palette.card;
    return Container(
      decoration: BoxDecoration(
        color: gradient == null
            ? (useDefaultCardColor ? theme.cardColor : color)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              borderColor ??
              theme.dividerColor.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.72 : 1,
              ),
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}
