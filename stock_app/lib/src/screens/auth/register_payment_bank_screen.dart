import 'package:flutter/material.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';
import 'register_notifications_screen.dart';

class RegisterPaymentBankScreen extends StatefulWidget {
  const RegisterPaymentBankScreen({super.key});

  @override
  State<RegisterPaymentBankScreen> createState() =>
      _RegisterPaymentBankScreenState();
}

class _RegisterPaymentBankScreenState extends State<RegisterPaymentBankScreen> {
  late final TextEditingController _holderController;
  late final TextEditingController _ibanController;
  late final TextEditingController _taxNumberController;
  late final TextEditingController _taxOfficeController;
  bool _controllersInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) {
      return;
    }
    final draft = StockAppScope.of(context).registrationDraft;
    _holderController = TextEditingController(text: draft.bankHolderName);
    _ibanController = TextEditingController(text: draft.iban);
    _taxNumberController = TextEditingController(text: draft.taxNumber);
    _taxOfficeController = TextEditingController(text: draft.taxOffice);
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _holderController.dispose();
    _ibanController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Adım 6 / 9',
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
                  const Text(
                    'Ödeme ve Banka Bilgileri',
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
                    'Kazançlarınızın sorunsuz aktarılması için ticari hesap bilgilerinizi ekleyin. Tüm verileriniz uçtan uca şifrelenir.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _buildInputField(
                          'Hesap Sahibi Adı Soyadı',
                          'Banka hesabında göründüğü gibi',
                          Icons.person_outline,
                          controller: _holderController,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          'IBAN Numarası',
                          'TR00 0000 0000 0000 0000 0000 00',
                          Icons.account_balance,
                          controller: _ibanController,
                          hintStyle: const TextStyle(letterSpacing: 1.0),
                          helperText:
                              'TR ile başlayan 26 haneli numaranızı giriniz.',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInputField(
                                'Vergi Numarası / TCKN',
                                '10 veya 11 haneli',
                                Icons.fingerprint,
                                controller: _taxNumberController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInputField(
                                'Vergi Dairesi',
                                'Örn: Kadıköy',
                                Icons.domain,
                                controller: _taxOfficeController,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Trust Indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Güvenli Veri Depolama',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bilgileriniz 256-bit SSL sertifikası ile korunmaktadır ve yalnızca ödeme işlemleri için kullanılır.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant.withValues(
                                    alpha: 0.8,
                                  ),
                                  height: 1.5,
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
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    onPressed: () {
                      _saveAndContinue(context);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Güvenli Kaydet ve Tamamla',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(text: 'Kayıt işlemini tamamlayarak '),
                        TextSpan(
                          text: 'Kullanım Koşulları',
                          style: TextStyle(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: '\'nı kabul etmiş sayılırsınız.'),
                      ],
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

  Widget _buildInputField(
    String label,
    String hint,
    IconData icon, {
    required TextEditingController controller,
    TextStyle? hintStyle,
    String? helperText,
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
              color: AppColors.onSurface,
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
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  hintStyle ??
                  const TextStyle(
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w500,
                  ),
              prefixIcon: Icon(icon, color: AppColors.slate400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              helperText,
              style: const TextStyle(fontSize: 11, color: AppColors.slate400),
            ),
          ),
      ],
    );
  }

  void _saveAndContinue(BuildContext context) {
    final draft = StockAppScope.of(context).registrationDraft;
    draft.bankHolderName = _holderController.text.trim();
    draft.iban = _ibanController.text.trim();
    draft.taxNumber = _taxNumberController.text.trim();
    draft.taxOffice = _taxOfficeController.text.trim();
    if (draft.bankName.trim().isEmpty) {
      draft.bankName = 'Banka bilgisi';
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterNotificationsScreen()),
    );
  }
}
