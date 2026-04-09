import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

class FaqTile extends StatelessWidget {
  const FaqTile({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Palette.cardWarm,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: ExpansionTile(
          collapsedIconColor: Palette.muted,
          iconColor: Palette.red,
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: <Widget>[
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(
                color: Palette.soft.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
