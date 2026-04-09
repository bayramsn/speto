import 'package:flutter/material.dart';

/// Breakpoints for responsive design.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Returns true if the screen is at least tablet-width.
bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= Breakpoints.mobile;

/// Returns true if the screen is desktop-width.
bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

/// Responsive builder that provides different layouts per breakpoint.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= Breakpoints.mobile && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// Responsive padding — wider screens get more padding.
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= Breakpoints.desktop
        ? (width - 1000) / 2
        : width >= Breakpoints.mobile
            ? 32.0
            : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal.clamp(16.0, 200.0)),
      child: child,
    );
  }
}

/// Responsive grid — 1 column on mobile, 2 on tablet, 3 on desktop.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= Breakpoints.desktop
            ? 3
            : constraints.maxWidth >= Breakpoints.mobile
                ? 2
                : 1;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }
}
