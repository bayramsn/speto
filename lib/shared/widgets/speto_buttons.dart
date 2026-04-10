import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpetoPrimaryButton extends StatelessWidget {
  const SpetoPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = theme.colorScheme.primary;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(999),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.45 : 0.28),
                blurRadius: isDark ? 32 : 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (icon != null) ...<Widget>[
                  const SizedBox(width: 10),
                  Icon(icon, color: Colors.white, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SpetoSecondaryButton extends StatelessWidget {
  const SpetoSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 40,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: double.infinity,
          height: height,
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
