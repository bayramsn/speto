import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'speto_card.dart';

class IconMetric extends StatelessWidget {
  const IconMetric({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SpetoCard(
        radius: 18,
        color: Palette.cardWarm,
        child: Column(
          children: <Widget>[
            Icon(icon, color: Palette.orange, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Palette.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
