import 'package:flutter/material.dart';

import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';

class StudentEmailRegisterScreen extends StatefulWidget {
  const StudentEmailRegisterScreen({super.key});

  @override
  State<StudentEmailRegisterScreen> createState() =>
      _StudentEmailRegisterScreenState();
}

class _StudentEmailRegisterScreenState
    extends State<StudentEmailRegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _acceptKvkk = true;
  bool _acceptTerms = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(SpetoAppState appState) async {
    final String email = _emailController.text.trim();
    final bool validStudentEmail = RegExp(
      r'^[^@\s]+@[^@\s]+\.edu(\.tr)?$',
      caseSensitive: false,
    ).hasMatch(email);
    final bool strongPassword =
        _passwordController.text.length >= 8 &&
        RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(_passwordController.text) &&
        RegExp(r'\d').hasMatch(_passwordController.text);

    if (!_acceptKvkk || !_acceptTerms) {
      SpetoToast.show(
        context,
        message: 'Sözleşmeleri onaylamadan kayıt olunamaz.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    if (_nameController.text.trim().isEmpty ||
        email.isEmpty ||
        _phoneController.text.trim().isEmpty ||
        !validStudentEmail ||
        !strongPassword) {
      SpetoToast.show(
        context,
        message:
            'Ad soyad, telefon, edu uzantılı e-posta ve güçlü şifre gerekli.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    await appState.startRegistration(
      fullName: _nameController.text,
      email: email,
      phone: _phoneController.text,
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    if (appState.supportsFirebaseEmailLink) {
      final bool sent = await appState.sendRegistrationEmailLink();
      if (!mounted) {
        return;
      }
      if (!sent) {
        SpetoToast.show(
          context,
          message:
              'Mail linki şu an gönderilemedi. Doğrulamaya kod ekranı ile devam ediliyor.',
          icon: Icons.info_outline_rounded,
        );
        openScreen(context, SpetoScreen.otpVerification);
        return;
      }
      openScreen(context, SpetoScreen.emailLinkPending);
      return;
    }
    openScreen(context, SpetoScreen.otpVerification);
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    return SpetoScreenScaffold(
      title: 'Öğrenci Kaydı',
      background: Palette.aubergine,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF2A1814), Color(0xFF121015)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Palette.orange.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Palette.orange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Palette.orange,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'edu doğrulama',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Palette.orange,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Öğrenci mail adresinle kampüs kaydını başlat.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'edu uzantılı okul e-postanla kayıt olduğunda öğrenci dostu fırsatlar, kampüs akışları ve özel deneyim alanları açılır.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Palette.soft,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const <Widget>[
                      InfoTag(
                        label: 'Kampüs fırsatları',
                        icon: Icons.local_offer_outlined,
                      ),
                      InfoTag(
                        label: 'Öğrenci menüleri',
                        icon: Icons.restaurant_menu_rounded,
                      ),
                      InfoTag(
                        label: 'Hızlı doğrulama',
                        icon: Icons.verified_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Öğrenci Bilgileri',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Mail doğrulama ve öğrenci fırsatları için temel bilgilerini gir.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Palette.soft),
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: 'Ad Soyad',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Öğrenci E-postası',
              controller: _emailController,
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 6),
            Text(
              'Örnek: ad.soyad@universite.edu.tr',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Palette.muted),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Telefon Numarası',
              controller: _phoneController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Şifre',
              controller: _passwordController,
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              trailing: GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Palette.muted,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Şifren en az 8 karakter, sayı ve büyük harf içermeli.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Palette.muted),
            ),
            const SizedBox(height: 16),
            _studentConsentRow(
              context,
              'KVKK Metnini okudum ve kabul ediyorum.',
              value: _acceptKvkk,
              onTap: () => setState(() => _acceptKvkk = !_acceptKvkk),
            ),
            const SizedBox(height: 10),
            _studentConsentRow(
              context,
              'Kullanıcı sözleşmesini okudum ve onaylıyorum.',
              value: _acceptTerms,
              onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            ),
            const SizedBox(height: 18),
            SpetoPrimaryButton(
              label: 'Öğrenci Kaydını Başlat',
              icon: Icons.arrow_forward_rounded,
              onTap: () => _submit(appState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentConsentRow(
    BuildContext context,
    String label, {
    required bool value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: value ? Palette.red.withValues(alpha: 0.18) : null,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value
                    ? Palette.red
                    : Colors.white.withValues(alpha: 0.24),
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, size: 14, color: Palette.red)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Palette.soft),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// InfoTag
// ---------------------------------------------------------------------------

class InfoTag extends StatelessWidget {
  const InfoTag({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Palette.orange),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Palette.soft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
