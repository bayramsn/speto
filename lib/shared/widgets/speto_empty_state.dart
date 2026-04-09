import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'speto_buttons.dart';

class SpetoEmptyState extends StatelessWidget {
  const SpetoEmptyState({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.primaryButtonLabel,
    this.primaryButtonIcon,
    this.onPrimaryButtonTap,
    this.secondaryButtonLabel,
    this.onSecondaryButtonTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? primaryButtonLabel;
  final IconData? primaryButtonIcon;
  final VoidCallback? onPrimaryButtonTap;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryButtonTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? Palette.cardWarm : PaletteLight.cardWarm;
    final Color softColor = isDark ? Palette.soft : PaletteLight.soft;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 48),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, size: 38, color: iconColor),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: context.spetoSectionTitleStyle(fontSize: 17.5),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: context.spetoDescriptionStyle(
              color: softColor.withValues(alpha: 0.72),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (primaryButtonLabel != null && onPrimaryButtonTap != null)
          SpetoPrimaryButton(
            label: primaryButtonLabel!,
            icon: primaryButtonIcon,
            onTap: onPrimaryButtonTap!,
          ),
        if (secondaryButtonLabel != null &&
            onSecondaryButtonTap != null) ...<Widget>[
          const SizedBox(height: 12),
          SpetoSecondaryButton(
            label: secondaryButtonLabel!,
            onTap: onSecondaryButtonTap!,
          ),
        ],
      ],
    );
  }
}
