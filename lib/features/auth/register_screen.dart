import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.prefillName,
    this.prefillEmail,
    this.socialProviderKey,
    this.socialProviderLabel,
  });

  final String? prefillName;
  final String? prefillEmail;
  final String? socialProviderKey;
  final String? socialProviderLabel;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _acceptKvkk = true;
  bool _acceptTerms = true;
  bool _obscurePassword = true;

  bool get _isSocialRegistration =>
      widget.socialProviderKey != null && widget.socialProviderLabel != null;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.prefillName ?? '';
    _emailController.text = widget.prefillEmail ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(SpetoAppState appState) async {
    if (!_acceptKvkk || !_acceptTerms) {
      SpetoToast.show(
        context,
        message: 'Sözleşmeleri onaylamadan kayıt olunamaz.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    final bool invalidStandardPassword =
        _passwordController.text.length < 8 ||
        !RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(_passwordController.text) ||
        !RegExp(r'\d').hasMatch(_passwordController.text);
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        (!_isSocialRegistration && invalidStandardPassword)) {
      SpetoToast.show(
        context,
        message: _isSocialRegistration
            ? 'Ad, e-posta ve telefon alanları gerekli.'
            : 'Ad, e-posta, telefon ve güçlü bir şifre gerekli.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    final bool hasExistingAccount = await appState.hasAccountForEmail(
      _emailController.text,
    );
    if (hasExistingAccount) {
      if (!mounted) {
        return;
      }
      SpetoToast.show(
        context,
        message:
            'Bu e-posta zaten kayıtlı. Giriş yapmayı deneyin veya farklı bir e-posta kullanın.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    await appState.startRegistration(
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _isSocialRegistration
          ? 'social-${widget.socialProviderKey}'
          : _passwordController.text,
    );
    final SpetoRegistrationOtpVerificationResult result = await appState
        .verifyOtpCode(appState.testOtpCode);
    if (!mounted) {
      return;
    }
    if (result != SpetoRegistrationOtpVerificationResult.verified) {
      final String message = switch (result) {
        SpetoRegistrationOtpVerificationResult.emailAlreadyRegistered =>
          'Bu e-posta zaten kayıtlı. Giriş yapmayı deneyin veya farklı bir e-posta kullanın.',
        SpetoRegistrationOtpVerificationResult.unavailable ||
        SpetoRegistrationOtpVerificationResult.invalidCode =>
          'Kayıt tamamlanamadı. Lütfen tekrar deneyin.',
        SpetoRegistrationOtpVerificationResult.verified => '',
      };
      SpetoToast.show(
        context,
        message: message,
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    openRootScreen(context, SpetoScreen.home);
  }

  Future<void> _continueWithSocialProvider(
    SpetoAppState appState, {
    required String provider,
    required String providerLabel,
  }) async {
    final SocialSignInDraft? draft = await showSocialSignInSheet(
      context,
      providerLabel: providerLabel,
    );
    if (draft == null) {
      return;
    }
    final bool hasAccount = await appState.hasAccountForEmail(draft.email);
    if (hasAccount) {
      await appState.signIn(
        email: draft.email,
        password: 'social-$provider',
        displayName: draft.displayName,
        trustedProvider: true,
      );
      if (!mounted) {
        return;
      }
      SpetoToast.show(
        context,
        message: '$providerLabel hesabın bulundu, giriş yapıldı.',
        icon: Icons.login_rounded,
      );
      openRootScreen(context, SpetoScreen.home);
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      spetoRoute(
        RegisterScreen(
          prefillName: draft.displayName,
          prefillEmail: draft.email,
          socialProviderKey: provider,
          socialProviderLabel: providerLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    return SpetoScreenScaffold(
      title: 'Kayıt Ol',
      background: Palette.aubergine,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _isSocialRegistration
                  ? '${widget.socialProviderLabel} ile Kaydı Tamamla'
                  : "SepetPro'ya Katıl",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              _isSocialRegistration
                  ? '${widget.socialProviderLabel} hesabınla devam etmek için telefonunu tamamla ve doğrulamayı bitir.'
                  : 'Hemen üye ol, market ve restoranlardan sipariş vermeye başla.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Palette.soft, height: 1.6),
            ),
            const SizedBox(height: 28),
            LabeledField(
              label: 'Ad Soyad',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'E-posta',
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Telefon Numarası',
              controller: _phoneController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            if (_isSocialRegistration) ...<Widget>[
              const SizedBox(height: 16),
              SpetoCard(
                radius: 16,
                color: Palette.cardWarm,
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Palette.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: Palette.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${widget.socialProviderLabel} hesabın doğrulandıktan sonra bu e-posta ile giriş yapabileceksin.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Palette.soft,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
              Text(
                'Şifren en az 8 karakter, sayı ve büyük harf içermeli.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Palette.muted),
              ),
            ],
            const SizedBox(height: 20),
            _checkRow(
              context,
              'KVKK Metnini okudum ve kabul ediyorum.',
              value: _acceptKvkk,
              onTap: () => setState(() => _acceptKvkk = !_acceptKvkk),
            ),
            const SizedBox(height: 12),
            _checkRow(
              context,
              'Kullanıcı sözleşmesini okudum ve onaylıyorum.',
              value: _acceptTerms,
              onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            ),
            const SizedBox(height: 24),
            SpetoPrimaryButton(
              label: _isSocialRegistration
                  ? '${widget.socialProviderLabel} ile Devam Et'
                  : 'KAYIT OL',
              onTap: () => _submit(appState),
            ),
            if (!_isSocialRegistration) ...<Widget>[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => openScreen(context, SpetoScreen.studentRegister),
                child: SpetoCard(
                  radius: 18,
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF2B1914), Color(0xFF120F15)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Palette.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Palette.orange,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Öğrenci mail adresi ile kayıt ol',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'edu uzantılı okul mailinle kampüs fırsatlarını ayrı akışta aç.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Palette.soft, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Palette.soft,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.1)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'veya',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white54),
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SocialProviderCard(
              label: 'Google ile devam et',
              icon: googleBrandIcon(),
              onTap: () => _continueWithSocialProvider(
                appState,
                provider: 'google',
                providerLabel: 'Google',
              ),
            ),
            const SizedBox(height: 16),
            SocialProviderCard(
              label: 'Apple ile devam et',
              icon: const FaIcon(
                FontAwesomeIcons.apple,
                color: Colors.white,
                size: 20,
              ),
              onTap: () => _continueWithSocialProvider(
                appState,
                provider: 'apple',
                providerLabel: 'Apple',
              ),
            ),
            const SizedBox(height: 16),
            SocialProviderCard(
              label: 'Facebook ile devam et',
              icon: const FaIcon(
                FontAwesomeIcons.facebookF,
                color: Colors.white,
                size: 18,
              ),
              onTap: () => _continueWithSocialProvider(
                appState,
                provider: 'facebook',
                providerLabel: 'Facebook',
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text.rich(
                TextSpan(
                  text: 'Zaten hesabın var mı? ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                  children: <InlineSpan>[
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(
                            color: Palette.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkRow(
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
