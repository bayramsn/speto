import 'package:flutter/material.dart';

import '../../core/data/default_data.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool get _hasMinLength => _passwordController.text.length >= 8;

  bool get _hasUppercase =>
      RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(_passwordController.text);

  bool get _hasDigit => RegExp(r'\d').hasMatch(_passwordController.text);

  bool get _passwordsMatch =>
      _confirmController.text.isNotEmpty &&
      _passwordController.text == _confirmController.text;

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) {
      score += 1;
    }
    if (_hasUppercase) {
      score += 1;
    }
    if (_hasDigit) {
      score += 1;
    }
    if (_passwordsMatch) {
      score += 1;
    }
    return score;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final String? resetEmail = appState.pendingPasswordResetEmail;
    final bool emailResetFlow =
        appState.session == null &&
        appState.pendingRegistration == null &&
        resetEmail != null &&
        resetEmail.trim().isNotEmpty;
    final bool resetVerified =
        !emailResetFlow || appState.isPasswordResetOtpVerified;
    return SpetoScreenScaffold(
      title: emailResetFlow ? 'Yeni Şifre Oluştur' : 'Şifreyi Sıfırla',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              emailResetFlow
                  ? resetVerified
                        ? '${maskEmailAddress(resetEmail)} hesabı doğrulandı. Şimdi yeni ve güçlü bir şifre belirleyin.'
                        : 'Yeni şifre oluşturmadan önce e-posta kodunu doğrulamanız gerekiyor.'
                  : 'Yeni ve güçlü bir şifre belirleyin.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Palette.soft,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            if (emailResetFlow) ...<Widget>[
              SpetoCard(
                radius: 20,
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF261914), Color(0xFF16161A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: resetVerified
                            ? Palette.green.withValues(alpha: 0.14)
                            : Palette.orange.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        resetVerified
                            ? Icons.verified_outlined
                            : Icons.mark_email_unread_outlined,
                        color: resetVerified ? Palette.green : Palette.orange,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            resetVerified
                                ? 'Doğrulama tamamlandı'
                                : 'Kod doğrulaması bekleniyor',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            maskEmailAddress(resetEmail),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Palette.soft, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (emailResetFlow && !resetVerified) ...<Widget>[
              SpetoPrimaryButton(
                label: 'E-POSTA KODUNU DOĞRULA',
                icon: Icons.mark_email_read_outlined,
                onTap: () => openScreen(context, SpetoScreen.otpVerification),
              ),
              const SizedBox(height: 12),
              SpetoSecondaryButton(
                label: 'ŞİFREMİ UNUTTUM EKRANINA DÖN',
                onTap: () => openScreen(context, SpetoScreen.forgotPassword),
              ),
            ] else ...<Widget>[
              LabeledField(
                label: 'Yeni Şifre',
                controller: _passwordController,
                icon: Icons.lock_outline_rounded,
                onChanged: (_) => setState(() {}),
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
              const SizedBox(height: 18),
              SpetoCard(
                radius: 18,
                color: Palette.cardWarm,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Şifre Gücü',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          _strengthScore >= 4
                              ? 'Güçlü'
                              : _strengthScore >= 2
                              ? 'Orta'
                              : 'Zayıf',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _strengthScore >= 4
                                    ? Palette.green
                                    : _strengthScore >= 2
                                    ? Palette.orange
                                    : Palette.crimson,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: List<Widget>.generate(4, (int index) {
                        final int filled = _strengthScore;
                        final Color color = index < filled
                            ? _strengthScore >= 4
                                  ? Palette.green
                                  : _strengthScore >= 2
                                  ? Palette.orange
                                  : Palette.crimson
                            : Colors.white12;
                        return Expanded(
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    _checkHint(
                      context,
                      'En az 8 karakter',
                      active: _hasMinLength,
                    ),
                    const SizedBox(height: 8),
                    _checkHint(
                      context,
                      'Sayı ve büyük harf içeriyor',
                      active: _hasDigit && _hasUppercase,
                    ),
                    const SizedBox(height: 8),
                    _checkHint(
                      context,
                      'Şifreler eşleşiyor',
                      active: _passwordsMatch,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              LabeledField(
                label: 'Yeni Şifre (Tekrar)',
                controller: _confirmController,
                icon: Icons.lock_reset_rounded,
                onChanged: (_) => setState(() {}),
                obscureText: _obscureConfirm,
                trailing: GestureDetector(
                  onTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  child: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Palette.muted,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              SpetoPrimaryButton(
                label: 'ŞİFREYİ GÜNCELLE',
                icon: Icons.arrow_forward_rounded,
                onTap: () async {
                  if (!_hasMinLength || !_hasUppercase || !_hasDigit) {
                    SpetoToast.show(
                      context,
                      message:
                          'Şifre en az 8 karakter olmalı, sayı ve büyük harf içermeli.',
                      icon: Icons.info_outline_rounded,
                    );
                    return;
                  }
                  if (!_passwordsMatch) {
                    SpetoToast.show(
                      context,
                      message: 'Şifreler eşleşmeli.',
                      icon: Icons.info_outline_rounded,
                    );
                    return;
                  }
                  final bool updated = await appState.updatePassword(
                    password: _passwordController.text,
                  );
                  if (!updated) {
                    if (!context.mounted) {
                      return;
                    }
                    SpetoToast.show(
                      context,
                      message:
                          'Şifre güncellemek için aktif bir hesap bulunamadı.',
                      icon: Icons.info_outline_rounded,
                    );
                    return;
                  }
                  if (!context.mounted) {
                    return;
                  }
                  openScreen(context, SpetoScreen.passwordSuccess);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _checkHint(BuildContext context, String text, {required bool active}) {
    return Row(
      children: <Widget>[
        Icon(
          active ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 14,
          color: active ? Palette.green : Palette.faint,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Palette.soft),
        ),
      ],
    );
  }
}
