import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'register_basic_info_screen.dart';

class RegisterBusinessTypeScreen extends StatelessWidget {
  const RegisterBusinessTypeScreen({super.key});

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
                  // Progress Indicator
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7E8E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1 / 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Adım 1/8',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Hero Content
                  const Text(
                    'İşletme türünüz nedir?',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Size en uygun araçları sunabilmemiz için işletmenizi kategorize edelim.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Selection Cards
                  _buildTypeCard(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'Market',
                    subtitle:
                        'Gıda, şarküteri, manav veya süpermarket işletmeleri için hızlı stok yönetimi.',
                    onTap: () {
                      _selectType(
                        context,
                        SpetoStorefrontType.market,
                        'Market',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTypeCard(
                    context,
                    icon: Icons.restaurant,
                    title: 'Restoran',
                    subtitle:
                        'Restoran ve yemek üretim yerleri için sipariş, kampanya ve mutfak takibi.',
                    onTap: () {
                      _selectType(
                        context,
                        SpetoStorefrontType.restaurant,
                        'Restoran',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTypeCard(
                    context,
                    icon: Icons.store,
                    title: 'Diğer İşletme',
                    subtitle:
                        'Kafe, pastane gibi Happy Hour yayınlayacak ve hızlı satış yapacak tüm diğer noktalar için.',
                    onTap: () {
                      _selectType(
                        context,
                        SpetoStorefrontType.market,
                        'Diğer İşletme',
                      );
                    },
                  ),
                  const SizedBox(height: 48),

                  // Sub-banner Feature
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F5),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          right: -40,
                          top: 0,
                          bottom: 0,
                          width: 200,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                            ),
                            foregroundDecoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              backgroundBlendMode: BlendMode.multiply,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF3F4F5),
                                    AppColors.primaryContainer.withValues(
                                      alpha: 0.2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'NEDEN SEPETPRO?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'İşinizi dijital\ndünyaya taşırken\nyanınızdayız.',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer Info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F5).withValues(alpha: 0.5),
                border: const Border(top: BorderSide(color: Color(0xFFE7E8E9))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE1E3E4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: AppColors.slate600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Yardıma mı ihtiyacınız var? Destek ekibimizle görüşün.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w600,
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

  Widget _buildTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Text(
                  'Seç ve Devam Et',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectType(
    BuildContext context,
    SpetoStorefrontType type,
    String category,
  ) {
    final controller = StockAppScope.of(context);
    controller.registrationDraft.storefrontType = type;
    controller.registrationDraft.businessCategory = category;
    controller.registrationDraft.businessSubtitle = '$category operasyonu';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterBasicInfoScreen()),
    );
  }
}
