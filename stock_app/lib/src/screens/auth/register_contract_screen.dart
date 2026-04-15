import 'package:flutter/material.dart';
import '../../app/stock_app_scope.dart';
import '../../theme/app_colors.dart';

class RegisterContractScreen extends StatefulWidget {
  const RegisterContractScreen({super.key});

  @override
  State<RegisterContractScreen> createState() => _RegisterContractScreenState();
}

class _RegisterContractScreenState extends State<RegisterContractScreen> {
  bool _termsChecked = false;
  bool _kvkkChecked = false;
  bool _marketingChecked = false;
  bool _submitting = false;

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
                'Adım 9/9',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
            // Head
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.verified,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Son Adım: Onay ve Sözleşmeler',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'İşletmenizi SepetPro ekosistemine dahil etmek için lütfen aşağıdaki belgeleri inceleyin ve onaylayın.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.slate500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Terms Box
            _buildAgreementBox(
              title: 'Kullanım Şartları',
              icon: Icons.gavel,
              content:
                  '1. Taraflar ve Kapsam\nBu sözleşme SepetPro ile kayıt olan İşletme arasındaki dijital hizmet kullanım şartlarını belirler...\n\n2. Hizmet Tanımı\nSepetPro, yerel işletmelerin sipariş ve envanter yönetimini optimize eden bir B2B platformudur. İşletme, platform üzerinden verilen her türlü siparişten kendisi sorumludur.\n\n3. Ödeme Koşulları\nPlatform kullanım bedeli, seçilen pakete göre aylık veya yıllık olarak tahsil edilir. Geciken ödemelerde hizmet askıya alınabilir.\n\nSözleşmenin devamını okumak için lütfen aşağı kaydırın. Tüm maddeler işletme güvenliği için tasarlanmıştır.',
              buttonText: 'Tam Ekran Gör',
              checkboxText:
                  'Kullanım Şartları\'nı okudum ve tüm maddeleri kabul ediyorum.',
              checked: _termsChecked,
              onChanged: (val) => setState(() => _termsChecked = val ?? false),
            ),
            const SizedBox(height: 16),

            // KVKK Box
            _buildAgreementBox(
              title: 'KVKK Aydınlatma Metni',
              icon: Icons.security,
              content:
                  'Veri Sorumlusu Bilgilendirmesi\n6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") uyarınca, verileriniz SepetPro tarafından işlenmektedir.\n\nİşleme Amaçları\nİşletme yetkilisi kimlik bilgileri, iletişim bilgileri ve ticari işlem güvenliği verileri hizmetin sunulabilmesi amacıyla kaydedilir.\n\nVerileriniz, yasal zorunluluklar haricinde üçüncü taraflarla paylaşılmaz. Haklarınız için destek@sepetpro.com üzerinden bizimle iletişime geçebilirsiniz.',
              buttonText: 'PDF İndir',
              checkboxText:
                  'Kişisel verilerimin işlenmesine dair aydınlatma metnini onaylıyorum.',
              checked: _kvkkChecked,
              onChanged: (val) => setState(() => _kvkkChecked = val ?? false),
            ),
            const SizedBox(height: 24),

            // Marketing Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _marketingChecked,
                    onChanged: (val) =>
                        setState(() => _marketingChecked = val ?? false),
                    activeColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'SepetPro tarafından sunulan kampanya, indirim ve yeni özellikler hakkında ticari elektronik ileti almayı kabul ediyorum. (İsteğe Bağlı)',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Final CTA Box
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'HAZIRSINIZ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SepetPro Ailesine Katılmaya Bir Tık Uzaktasınız',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    onPressed: (_termsChecked && _kvkkChecked && !_submitting)
                        ? () => _submitRegistration(context)
                        : null,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Kayıt İşlemini Tamamla',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.rocket_launch, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tıklayarak üyelik sürecinizi başlatmış olacaksınız. Aktivasyon e-postası kayıtlı adresinize gönderilecektir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, size: 16, color: AppColors.slate500),
                  SizedBox(width: 8),
                  Text(
                    'Bilgilerimi Gözden Geçir',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementBox({
    required String title,
    required IconData icon,
    required String content,
    required String buttonText,
    required String checkboxText,
    required bool checked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 140,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slate600,
                  height: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.05),
                border: Border.all(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: checked,
                      onChanged: onChanged,
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      checkboxText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRegistration(BuildContext context) async {
    final controller = StockAppScope.of(context);
    controller.registrationDraft.termsAccepted = _termsChecked;
    controller.registrationDraft.privacyAccepted = _kvkkChecked;
    controller.registrationDraft.marketingOptIn = _marketingChecked;
    setState(() => _submitting = true);
    final bool success = await controller.registerOperator();
    if (!context.mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    final String message =
        controller.authError ?? 'Kayıt tamamlanamadı. Bilgileri kontrol edin.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
