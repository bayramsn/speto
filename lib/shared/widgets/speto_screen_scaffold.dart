import 'package:flutter/material.dart';

import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/theme/palette.dart';
import 'home_bottom_nav_bar.dart';

Widget roundButton(
  BuildContext context, {
  required IconData icon,
  required VoidCallback onTap,
  Color color = Colors.white,
  String? semanticLabel,
}) {
  final ThemeData theme = Theme.of(context);
  final bool isDark = theme.brightness == Brightness.dark;
  return Semantics(
    button: true,
    label: semanticLabel ?? 'Düğme',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : PaletteLight.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.72 : 1),
          ),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    ),
  );
}

class SpetoScreenScaffold extends StatelessWidget {
  const SpetoScreenScaffold({
    super.key,
    this.title,
    required this.body,
    this.footer,
    this.showBottomNav = false,
    this.activeNav = NavSection.explore,
    this.showBack = true,
    this.background = Palette.base,
    this.actions = const <Widget>[],
    this.onBack,
    this.backFallbackScreen,
  });

  final String? title;
  final Widget body;
  final Widget? footer;
  final bool showBottomNav;
  final NavSection activeNav;
  final bool showBack;
  final Color background;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final SpetoScreen? backFallbackScreen;

  @override
  Widget build(BuildContext context) {
    final bool showHeader = showBack || title != null || actions.isNotEmpty;
    final NavigatorState navigator = Navigator.of(context);
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            if (showHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: <Widget>[
                    if (showBack)
                      roundButton(
                        context,
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap:
                            onBack ??
                            () {
                              if (navigator.canPop()) {
                                navigator.pop();
                                return;
                              }
                              if (backFallbackScreen != null) {
                                openRootScreen(context, backFallbackScreen!);
                              }
                            },
                      )
                    else
                      const SizedBox(width: 40),
                    Expanded(
                      child: title == null
                          ? const SizedBox.shrink()
                          : Text(
                              title!,
                              textAlign: TextAlign.center,
                              style: context.spetoScreenTitleStyle(),
                            ),
                    ),
                    if (actions.isEmpty)
                      const SizedBox(width: 40)
                    else
                      Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ],
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (footer case final Widget footerWidget) footerWidget,
          if (showBottomNav) HomeBottomNavBar(active: activeNav),
        ],
      ),
    );
  }
}
