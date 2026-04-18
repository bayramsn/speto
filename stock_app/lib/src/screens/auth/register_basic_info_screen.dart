import 'package:flutter/material.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'register_location_screen.dart';

class RegisterBasicInfoScreen extends StatefulWidget {
  const RegisterBasicInfoScreen({super.key});

  @override
  State<RegisterBasicInfoScreen> createState() =>
      _RegisterBasicInfoScreenState();
}

class _RegisterBasicInfoScreenState extends State<RegisterBasicInfoScreen> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  bool _controllersInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) {
      return;
    }
    final draft = StockAppScope.of(context).registrationDraft;
    _businessNameController = TextEditingController(text: draft.businessName);
    _displayNameController = TextEditingController(
      text: draft.operatorDisplayName,
    );
    _emailController = TextEditingController(text: draft.operatorEmail);
    _phoneController = TextEditingController(text: draft.operatorPhone);
    _passwordController = TextEditingController(text: draft.operatorPassword);
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
                            widthFactor: 2 / 8,
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
                        'Adım 2/8',
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
                    'Temel Bilgileriniz',
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
                    'Sizi ve işletmenizi tanıyabilmemiz için gerekli temel iletişim bilgilerini girin.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  _buildInputField(
                    'İşletme Adı',
                    'Örn: SepetPro Market',
                    Icons.storefront,
                    controller: _businessNameController,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    'Yetkili Ad Soyad',
                    'Adınız ve soyadınız',
                    Icons.person_outline,
                    controller: _displayNameController,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    'E-posta',
                    'isletmeniz@ornek.com',
                    Icons.mail_outline,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    'Cep Telefonu',
                    '0 (5XX) XXX XX XX',
                    Icons.phone_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    'Şifre',
                    'En az 8 karakter',
                    Icons.lock_outline,
                    controller: _passwordController,
                    obscureText: true,
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
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
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
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.slate400),
              prefixIcon: Icon(icon, color: AppColors.slate400),
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
    draft.businessName = _businessNameController.text.trim();
    draft.operatorDisplayName = _displayNameController.text.trim();
    draft.operatorEmail = _emailController.text.trim();
    draft.operatorPhone = _phoneController.text.trim();
    draft.operatorPassword = _passwordController.text;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterLocationScreen()),
    );
  }
}
