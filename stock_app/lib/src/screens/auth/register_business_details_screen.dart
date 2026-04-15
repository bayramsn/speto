import 'package:flutter/material.dart';
import 'package:speto_shared/speto_shared.dart';

import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'register_working_hours_screen.dart';

class RegisterBusinessDetailsScreen extends StatefulWidget {
  const RegisterBusinessDetailsScreen({super.key});

  @override
  State<RegisterBusinessDetailsScreen> createState() =>
      _RegisterBusinessDetailsScreenState();
}

class _RegisterBusinessDetailsScreenState
    extends State<RegisterBusinessDetailsScreen> {
  String selectedCuisine = 'burger';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final category = StockAppScope.of(
      context,
    ).registrationDraft.businessCategory.trim().toLowerCase();
    selectedCuisine = switch (category) {
      'market' => 'market',
      'manav' => 'manav',
      'şarküteri' || 'sarkuteri' => 'sarkuteri',
      'diğer işletme' || 'diger isletme' || 'kafe' => 'kafe',
      'pizza' => 'pizza',
      'kebap' => 'kebap',
      'kahve' => 'kahve',
      _ => 'burger',
    };
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final draft = StockAppScope.of(context).registrationDraft;
    final bool isMarket = draft.storefrontType == SpetoStorefrontType.market;
    final String typeLabel = isMarket ? 'Market' : 'Restoran';
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
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Adım 4/9',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            // Hero
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                children: [
                  TextSpan(text: 'İşletmenizi Dünyaya\n'),
                  TextSpan(
                    text: 'Lezzetle Tanıtın',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Restoranınızın karakterini belirleyen detayları ekleyin. Bu bilgiler müşterilerinizin sizi daha kolay bulmasını sağlar.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.slate500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Selection Area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Mutfak Türü Seçimi',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: isMarket
                        ? [
                            _buildCuisineCard(
                              'market',
                              'Market',
                              Icons.shopping_cart,
                            ),
                            _buildCuisineCard('manav', 'Manav', Icons.eco),
                            _buildCuisineCard(
                              'sarkuteri',
                              'Şarküteri',
                              Icons.storefront,
                            ),
                            _buildCuisineCard(
                              'kafe',
                              'Kafe',
                              Icons.coffee_maker,
                            ),
                          ]
                        : [
                            _buildCuisineCard(
                              'burger',
                              'Burger',
                              Icons.lunch_dining,
                            ),
                            _buildCuisineCard(
                              'pizza',
                              'Pizza',
                              Icons.local_pizza,
                            ),
                            _buildCuisineCard(
                              'kebap',
                              'Kebap',
                              Icons.outdoor_grill,
                            ),
                            _buildCuisineCard(
                              'kahve',
                              'Kahve',
                              Icons.coffee_maker,
                            ),
                          ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Aside Panel (Bottom on Mobile)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 48,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=800',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.bottomLeft,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kaydı Tamamla',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Müşterileriniz bu görünümü sevecek!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSummaryRow('İşletme Türü', typeLabel),
                  const Divider(color: Color(0xFFE7E8E9)),
                  _buildSummaryRow(
                    'Hizmet Alanı',
                    [
                      draft.district,
                      draft.city,
                    ].where((value) => value.trim().isNotEmpty).join(', '),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    onPressed: () {
                      draft.businessCategory = _categoryLabelFor(
                        selectedCuisine,
                      );
                      draft.businessSubtitle =
                          '${draft.businessCategory} operasyonu';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterWorkingHoursScreen(),
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
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Taslağı Kaydet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate500,
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuisineCard(String id, String label, IconData icon) {
    bool isSelected = selectedCuisine == id;
    return InkWell(
      onTap: () {
        setState(() {
          selectedCuisine = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _categoryLabelFor(String id) {
    return switch (id) {
      'market' => 'Market',
      'manav' => 'Manav',
      'sarkuteri' => 'Şarküteri',
      'kafe' => 'Kafe',
      'pizza' => 'Pizza',
      'kebap' => 'Kebap',
      'kahve' => 'Kahve',
      _ => 'Burger',
    };
  }
}
