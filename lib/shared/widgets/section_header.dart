import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
