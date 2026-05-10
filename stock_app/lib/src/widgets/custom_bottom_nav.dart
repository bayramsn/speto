import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItemData> _overviewItems = <_NavItemData>[
    _NavItemData(
      label: 'Anasayfa',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    _NavItemData(
      label: 'Siparişler',
      activeIcon: Icons.receipt_long_rounded,
      inactiveIcon: Icons.receipt_long_outlined,
    ),
    _NavItemData(
      label: 'Ürünler',
      activeIcon: Icons.inventory_2_rounded,
      inactiveIcon: Icons.inventory_2_outlined,
    ),
    _NavItemData(
      label: 'Kampanya',
      activeIcon: Icons.campaign_rounded,
      inactiveIcon: Icons.campaign_outlined,
    ),
    _NavItemData(
      label: 'Profil',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
    ),
  ];

  static const List<_NavItemData> _defaultItems = <_NavItemData>[
    _NavItemData(
      label: 'Anasayfa',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    _NavItemData(
      label: 'Siparişler',
      activeIcon: Icons.receipt_long_rounded,
      inactiveIcon: Icons.receipt_long_outlined,
    ),
    _NavItemData(
      label: 'Ürünler',
      activeIcon: Icons.inventory_2_rounded,
      inactiveIcon: Icons.inventory_2_outlined,
    ),
    _NavItemData(
      label: 'Kampanyalar',
      activeIcon: Icons.campaign_rounded,
      inactiveIcon: Icons.campaign_outlined,
    ),
    _NavItemData(
      label: 'Hesabım',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final bool isOverview = currentIndex == 0;
    final List<_NavItemData> items = isOverview
        ? _overviewItems
        : _defaultItems;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isOverview ? 28 : 20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isOverview
                  ? Colors.white.withValues(alpha: 0.94)
                  : const Color(0xCCF8FAFC),
              border: Border(
                top: BorderSide(
                  color: AppColors.slate200.withValues(alpha: 0.5),
                ),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(12, 9, 12, 16 + bottomInset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (int index = 0; index < items.length; index++)
                  Expanded(
                    child: _BottomNavItem(
                      data: items[index],
                      isActive: index == currentIndex,
                      activeBackground: isOverview
                          ? AppColors.emerald50
                          : AppColors.emerald100,
                      activeForeground: isOverview
                          ? AppColors.success
                          : AppColors.brandGreen,
                      onTap: () => onTap(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.data,
    required this.isActive,
    required this.activeBackground,
    required this.activeForeground,
    required this.onTap,
  });

  final _NavItemData data;
  final bool isActive;
  final Color activeBackground;
  final Color activeForeground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive ? activeForeground : AppColors.slate400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 10 : 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isActive ? data.activeIcon : data.inactiveIcon,
              size: 18,
              color: iconColor,
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: iconColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
}
