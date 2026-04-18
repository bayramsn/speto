import 'package:flutter/material.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'register_working_hours_screen.dart';

class RegisterLocationScreen extends StatefulWidget {
  const RegisterLocationScreen({super.key});

  @override
  State<RegisterLocationScreen> createState() => _RegisterLocationScreenState();
}

class _RegisterLocationScreenState extends State<RegisterLocationScreen> {
  late final TextEditingController _branchController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _addressController;
  bool _controllersInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) {
      return;
    }
    final draft = StockAppScope.of(context).registrationDraft;
    _branchController = TextEditingController(text: draft.pickupPointLabel);
    _cityController = TextEditingController(text: draft.city);
    _districtController = TextEditingController(text: draft.district);
    _addressController = TextEditingController(text: draft.pickupPointAddress);
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _branchController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    super.dispose();
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
                            widthFactor: 3 / 8,
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
                        'Adım 3/8',
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
                    'Konum ve Şube',
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
                    'Müşterilerin sizi haritada bulabilmesi ve siparişleri doğru adrese yönlendirebilmemiz için adres bilgilerinizi girin.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  _buildInputField(
                    'Şube Adı',
                    'Örn: Merkez Şube veya Kadıköy Şube',
                    Icons.business,
                    controller: _branchController,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          'İl',
                          'Seçiniz',
                          Icons.location_city,
                          controller: _cityController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          'İlçe',
                          'Seçiniz',
                          Icons.map,
                          controller: _districtController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    'Açık Adres',
                    'Mahalle, Sokak, No, Kat vs.',
                    Icons.home_work_outlined,
                    controller: _addressController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Map Placeholder Card
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Harita Konumu (İsteğe Bağlı)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7E8E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE1E3E4)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Konumu Haritada İşaretle',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Action Area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                border: const Border(top: BorderSide(color: Color(0xFFE7E8E9))),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: () {
                  _saveAndContinue(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Devam Et',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    IconData icon, {
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.slate400),
              prefixIcon: maxLines == 1
                  ? Icon(icon, color: AppColors.slate400)
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Icon(icon, color: AppColors.slate400),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveAndContinue(BuildContext context) {
    final draft = StockAppScope.of(context).registrationDraft;
    draft.pickupPointLabel = _branchController.text.trim();
    draft.city = _cityController.text.trim();
    draft.district = _districtController.text.trim();
    draft.pickupPointAddress = _addressController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterWorkingHoursScreen()),
    );
  }
}
