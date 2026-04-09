import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.icon,
    this.initialValue = '',
    this.controller,
    this.keyboardType,
    this.onChanged,
    this.obscureText = false,
    this.trailing,
  });

  final String label;
  final String initialValue;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color mutedColor = isDark ? Palette.muted : PaletteLight.muted;
    final Color fieldColor = isDark ? Palette.cardWarm : PaletteLight.cardWarm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: mutedColor,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.84 : 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              Icon(icon, color: mutedColor, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  initialValue: controller == null ? initialValue : null,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  obscureText: obscureText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                  ),
                ),
              ),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
        ),
      ],
    );
  }
}
