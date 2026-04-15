import 'package:flutter/material.dart';

import '../../app/stock_app_controller.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import '../../widgets/vendor_picker_button.dart';
import 'integrations_screen.dart';
import 'payment_finance_screen.dart';
import 'profile_details_screen.dart';
import 'support_center_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StockAppController controller = StockAppScope.of(context);
    final vendor = controller.selectedVendor;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        title: const Text(
          'Hesabım',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: AppColors.onSurface,
          ),
        ),
        actions: <Widget>[VendorPickerButton(controller: controller)],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ).copyWith(bottom: 120),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.slate100),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF171717),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.isRestaurantMode
                            ? Icons.fastfood
                            : Icons.local_grocery_store,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.photo_camera,
                          color: Colors.white,
                          size: 14,
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
                              vendor?.title ?? 'Mağaza',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vendor?.isActive == false ? 'Pasif' : 'Açık',
                              style: const TextStyle(
                                color: AppColors.emerald500,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vendor?.subtitle ??
                            controller.userProfile?.displayName ??
                            '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.slate500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vendor?.pickupPoints.isNotEmpty == true
                                  ? vendor!.pickupPoints.first.label
                                  : 'Merkez Şube',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.slate300),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: _groupDecoration(),
            child: Column(
              children: <Widget>[
                _buildSettingsItem(
                  context,
                  icon: Icons.person,
                  title: 'Profil Bilgileri',
                  subtitle: 'İşletme bilgilerinizi düzenleyin',
                  isLast: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileDetailsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.schedule,
                  title: 'Çalışma Saatleri',
                  subtitle:
                      vendor?.workingHoursLabel ?? 'Çalışma saati bilgisi',
                  isLast: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileDetailsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: _groupDecoration(),
            child: Column(
              children: <Widget>[
                _buildSettingsItem(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Ödeme ve Finans',
                  subtitle: 'Banka hesapları ve kazançlar',
                  isLast: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PaymentFinanceScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.notifications,
                  title: 'Bildirim Ayarları',
                  subtitle: controller.userProfile?.notificationsEnabled == true
                      ? 'Bildirimler açık'
                      : 'Bildirimler kapalı',
                  isLast: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileDetailsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.group,
                  title: 'Kullanıcı Yönetimi',
                  subtitle: 'Bu fazda devre dışı',
                  isLast: true,
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: _groupDecoration(),
            child: Column(
              children: <Widget>[
                _buildSettingsItem(
                  context,
                  icon: Icons.extension,
                  title: 'Entegrasyonlar',
                  subtitle: 'POS, yazarkasa ve diğer bağlantılar',
                  isLast: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const IntegrationsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.headset_mic,
                  title: 'Destek Merkezi',
                  subtitle: 'Yardım alın ve talep oluşturun',
                  isLast: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SupportCenterScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.verified_user,
                  title: 'Güvenlik',
                  subtitle: 'Bu fazda devre dışı',
                  isLast: true,
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFF1F1),
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.logout, size: 24),
            label: const Text(
              'Çıkış Yap',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: controller.logout,
          ),
        ],
      ),
    );
  }

  BoxDecoration _groupDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.slate100),
      boxShadow: <BoxShadow>[
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLast,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: AppColors.slate50)),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.emerald500, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                enabled ? Icons.chevron_right : Icons.lock_outline,
                color: AppColors.slate300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
