import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/data/default_data.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({super.key, required this.active});

  final NavSection active;

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final Color textColor = Palette.faint;
    final bool basketActive = active == NavSection.basket;
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 82,
                  padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.10),
                        Palette.surface.withValues(alpha: 0.88),
                        Palette.base.withValues(alpha: 0.95),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 30,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _navItem(
                        context,
                        section: NavSection.explore,
                        icon: Icons.travel_explore_rounded,
                        label: 'Keşfet',
                        activeColor: Palette.red,
                        inactiveColor: textColor,
                      ),
                      _navItem(
                        context,
                        section: NavSection.orders,
                        icon: Icons.receipt_long_rounded,
                        label: 'Sipariş',
                        activeColor: Palette.red,
                        inactiveColor: textColor,
                      ),
                      const SizedBox(width: 56),
                      _navItem(
                        context,
                        section: NavSection.points,
                        icon: Icons.stars_rounded,
                        label: 'Puan',
                        activeColor: Palette.red,
                        inactiveColor: textColor,
                      ),
                      _navItem(
                        context,
                        section: NavSection.profile,
                        icon: Icons.person_outline_rounded,
                        label: 'Profil',
                        activeColor: Palette.red,
                        inactiveColor: textColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -12,
              child: GestureDetector(
                onTap: () =>
                    openRootScreen(context, screenForNav(NavSection.basket)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: basketActive
                        ? const LinearGradient(
                            colors: <Color>[Color(0xFFFF6B00), Palette.red],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: <Color>[
                              Color(0xFF2B1B1B),
                              Color(0xFF18181B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: basketActive
                          ? Colors.white.withValues(alpha: 0.28)
                          : Palette.borderWarm,
                      width: 4,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: basketActive
                            ? Palette.red.withValues(alpha: 0.28)
                            : Colors.black26,
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: basketActive ? Palette.base : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            color: basketActive ? Colors.white : Palette.base,
                            size: 20,
                          ),
                        ),
                      ),
                      if (appState.cartCount > 0)
                        Positioned(
                          right: -4,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Palette.ink, width: 2),
                            ),
                            child: Text(
                              '${appState.cartCount}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Palette.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required NavSection section,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool isActive = section == active;
    return GestureDetector(
      onTap: () => openRootScreen(context, screenForNav(section)),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        scale: isActive ? 1 : 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: 64,
          height: 56,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.24)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.2,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
