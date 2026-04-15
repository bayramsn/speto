import 'package:flutter/material.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'register_visuals_screen.dart';

class RegisterNotificationsScreen extends StatefulWidget {
  const RegisterNotificationsScreen({super.key});

  @override
  State<RegisterNotificationsScreen> createState() =>
      _RegisterNotificationsScreenState();
}

class _RegisterNotificationsScreenState
    extends State<RegisterNotificationsScreen> {
  bool _newOrderNotif = true;
  bool _campaignNotif = true;
  bool _smsNotif = false;
  bool _pushNotif = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final draft = StockAppScope.of(context).registrationDraft;
    _newOrderNotif = draft.notifyNewOrders;
    _campaignNotif = draft.notifyCampaignTips;
    _smsNotif = draft.notifySms;
    _pushNotif = draft.notifyPush;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kayıt Ol',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Adım 7 / 9',
                style: TextStyle(
                  color: AppColors.slate400,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bildirim Ayarları',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'İşletmenizi yönetirken nasıl haberdar olmak istediğinizi seçin. Bu ayarları dilediğiniz zaman değiştirebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildNotificationSetting(
                    title: 'Yeni sipariş bildirimi',
                    description:
                        'Müşterileriniz sipariş verdiğinde anlık olarak bildirim alın ve hazırlık sürecini hızlandırın.',
                    icon: Icons.shopping_bag,
                    value: _newOrderNotif,
                    onChanged: (val) => setState(() => _newOrderNotif = val),
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationSetting(
                    title: 'Kampanya önerileri',
                    description:
                        'Satışlarınızı artıracak özel kampanya kurguları ve yapay zeka destekli pazarlama önerileri.',
                    icon: Icons.campaign,
                    value: _campaignNotif,
                    onChanged: (val) => setState(() => _campaignNotif = val),
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationSetting(
                    title: 'SMS Bildirimleri',
                    description:
                        'İnternet bağlantınız olmadığında bile önemli sipariş güncellemelerini SMS ile takip edin.',
                    icon: Icons.sms,
                    value: _smsNotif,
                    onChanged: (val) => setState(() => _smsNotif = val),
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationSetting(
                    title: 'Push bildirimleri izinleri',
                    description:
                        'Tarayıcı ve uygulama üzerinden finansal raporlar ve sistem duyuruları için izinler.',
                    icon: Icons.vibration,
                    value: _pushNotif,
                    onChanged: (val) => setState(() => _pushNotif = val),
                  ),
                ],
              ),
            ),
            // Bottom Action Area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFFF8F9FA)),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    onPressed: () {
                      final draft = StockAppScope.of(context).registrationDraft;
                      draft.notifyNewOrders = _newOrderNotif;
                      draft.notifyCampaignTips = _campaignNotif;
                      draft.notifySms = _smsNotif;
                      draft.notifyPush = _pushNotif;
                      draft.notifyCancellations = _pushNotif || _smsNotif;
                      draft.notifyLowStock = _pushNotif || _smsNotif;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterVisualsScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Devam Et',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSetting({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: value
              ? AppColors.primaryContainer.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryContainer,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE7E8E9),
          ),
        ],
      ),
    );
  }
}
