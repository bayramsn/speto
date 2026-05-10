import 'package:flutter/material.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'integrations_screen.dart';
import 'notification_settings_screen.dart';
import 'payment_finance_screen.dart';
import 'profile_details_screen.dart';
import 'support_center_screen.dart';
import 'working_hours_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final vendor = controller.selectedVendor;
    final String businessName = vendor?.title.trim().isNotEmpty == true
        ? vendor!.title
        : 'İşletme';
    final String businessSubtitle = _resolveBusinessSubtitle(controller);
    final String branchLabel = vendor?.pickupPoints.isNotEmpty == true
        ? vendor!.pickupPoints.first.label
        : 'Merkez Şube';
    final bool isActive = vendor?.isActive ?? true;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 64,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface.withValues(alpha: 0.82),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        titleSpacing: 24,
        title: const Text(
          'Hesabım',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            height: 32 / 24,
            color: AppColors.onSurface,
          ),
        ),
        actions: const <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 24),
            child: Center(child: _HeaderNotificationIcon()),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double horizontalInset = constraints.maxWidth > 704
              ? (constraints.maxWidth - 672) / 2
              : 16;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalInset,
              8,
              horizontalInset,
              124,
            ),
            children: <Widget>[
              _BusinessProfileCard(
                title: businessName,
                subtitle: businessSubtitle,
                branchLabel: branchLabel,
                isActive: isActive,
                storefrontIcon: _storefrontIcon(controller),
                imageUrl: vendor?.image ?? '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileDetailsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _SettingsGroup(
                children: <Widget>[
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Profil Bilgileri',
                    subtitle: 'İşletme bilgilerinizi düzenleyin',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileDetailsScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.access_time_rounded,
                    title: 'Çalışma Saatleri',
                    subtitle: 'Açılış, kapanış ve tatil günleri',
                    isLast: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const WorkingHoursScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsGroup(
                children: <Widget>[
                  _SettingsTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Ödeme ve Finans',
                    subtitle: 'Banka hesapları ve kazançlar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PaymentFinanceScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Bildirim Ayarları',
                    subtitle: 'Bildirim tercihlerinizi yönetin',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.group_outlined,
                    title: 'Kullanıcı Yönetimi',
                    subtitle: 'Personel ve yetki ayarları',
                    isLast: true,
                    onTap: () => _showFeatureNotice(
                      context,
                      'Kullanıcı yönetimi bu fazda aktif değil.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsGroup(
                children: <Widget>[
                  _SettingsTile(
                    icon: Icons.extension_outlined,
                    title: 'Entegrasyonlar',
                    subtitle: 'POS, yazarkasa ve diğer bağlantılar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const IntegrationsScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.support_agent_outlined,
                    title: 'Destek Merkezi',
                    subtitle: 'Yardım alın ve talep oluşturun',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const SupportCenterScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    title: 'Güvenlik',
                    subtitle: 'Şifre, 2FA ve oturum ayarları',
                    isLast: true,
                    onTap: () => _showFeatureNotice(
                      context,
                      'Güvenlik ayarları bu fazda aktif değil.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _LogoutButton(
                onTap: () {
                  controller.logout();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _resolveBusinessSubtitle(StockAppController controller) {
    final vendor = controller.selectedVendor;
    final List<String> candidates = <String>[
      vendor?.cuisine ?? '',
      vendor?.subtitle ?? '',
      controller.userProfile?.displayName ?? '',
      _storefrontLabel(controller),
    ];
    return candidates.firstWhere(
      (String value) => value.trim().isNotEmpty,
      orElse: () => 'İşletme bilgisi',
    );
  }

  String _storefrontLabel(StockAppController controller) {
    if (controller.isRestaurantMode) {
      return 'Restoran';
    }
    if (controller.isMarketMode) {
      return 'Market';
    }
    if (controller.isOtherBusinessMode) {
      return 'Diğer İşletme';
    }
    return 'İşletme';
  }

  IconData _storefrontIcon(StockAppController controller) {
    if (controller.isRestaurantMode) {
      return Icons.fastfood_rounded;
    }
    if (controller.isMarketMode) {
      return Icons.local_grocery_store_rounded;
    }
    return Icons.storefront_rounded;
  }

  void _showFeatureNotice(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _HeaderNotificationIcon extends StatelessWidget {
  const _HeaderNotificationIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.notifications_outlined,
              size: 17,
              color: AppColors.onSurface,
            ),
          ),
          Positioned(
            top: 0,
            right: -1,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessProfileCard extends StatelessWidget {
  const _BusinessProfileCard({
    required this.title,
    required this.subtitle,
    required this.branchLabel,
    required this.isActive,
    required this.storefrontIcon,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String branchLabel;
  final bool isActive;
  final IconData storefrontIcon;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(21),
          decoration: _groupDecoration(),
          child: Row(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF171717),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: imageUrl.trim().isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _AvatarFallback(
                                    storefrontIcon: storefrontIcon,
                                  ),
                            )
                          : _AvatarFallback(storefrontIcon: storefrontIcon),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 28 / 18,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isActive ? 'Açık' : 'Kapalı',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 15 / 10,
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.bodyText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            branchLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 16 / 12,
                              color: AppColors.bodyText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.slate300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.storefrontIcon});

  final IconData storefrontIcon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(0xFF171717),
      child: Center(child: Icon(storefrontIcon, size: 30, color: Colors.white)),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _groupDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isLast ? 24 : 0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: Color(0xFFF9FAFB))),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 20,
                height: 20,
                child: Icon(icon, size: 17, color: AppColors.success),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 16.5 / 11,
                        color: AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.slate300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _groupDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xFFF3F4F6)),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ],
  );
}
