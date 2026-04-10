import 'package:flutter/material.dart';

import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final bool usesEmailLink = appState.supportsFirebaseEmailLink;
    return SpetoScreenScaffold(
      title: '',
      actions: <Widget>[
        TextButton(
          onPressed: () => openScreen(context, SpetoScreen.helpCenter),
          child: const Text('Yardım'),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 24),
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Palette.card,
                borderRadius: BorderRadius.circular(40),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x22FF3D00), blurRadius: 28),
                ],
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Palette.red,
                size: 58,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Şifrenizi yenileyin',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              usesEmailLink
                  ? 'E-posta adresinizi girin. Hesabınızı doğrulamak ve yeni şifre belirlemek için giriş linkini hemen gönderelim.'
                  : 'E-posta adresinizi girin. Hesabınızı doğrulamak için 5 haneli güvenlik kodunu hemen gönderelim.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Palette.soft,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            LabeledField(
              label: 'E-posta Adresiniz',
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SpetoPrimaryButton(
              label: usesEmailLink ? 'LİNKİ GÖNDER' : 'KODU GÖNDER',
              icon: Icons.arrow_forward_rounded,
              onTap: () async {
                final String email = _emailController.text.trim();
                if (email.isEmpty) {
                  SpetoToast.show(
                    context,
                    message: 'Şifre yenilemek için e-posta adresi gerekli.',
                    icon: Icons.info_outline_rounded,
                  );
                  return;
                }
                final bool requested = usesEmailLink
                    ? await appState.sendPasswordResetEmailLink(email)
                    : await appState.requestPasswordReset(email: email);
                final bool fallbackToOtp =
                    usesEmailLink && !requested
                        ? await appState.requestPasswordReset(email: email)
                        : false;
                if (!requested) {
                  if (!context.mounted) {
                    return;
                  }
                  if (fallbackToOtp) {
                    SpetoToast.show(
                      context,
                      message:
                          'Mail link kotası dolu. Şifre yenilemeye kod ile devam ediliyor.',
                      icon: Icons.info_outline_rounded,
                    );
                    openScreen(context, SpetoScreen.otpVerification);
                    return;
                  }
                  SpetoToast.show(
                    context,
                    message: 'Bu e-posta ile kayıtlı bir hesap bulunamadı.',
                    icon: Icons.info_outline_rounded,
                  );
                  return;
                }
                if (!context.mounted) {
                  return;
                }
                openScreen(
                  context,
                  usesEmailLink
                      ? SpetoScreen.emailLinkPending
                      : SpetoScreen.otpVerification,
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              usesEmailLink
                  ? 'Bağlantı ulaşmadıysa maili kontrol et veya yeniden gönder.'
                  : 'Bağlantı ulaşmadıysa müşteri hizmetleri ile görüş.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => openScreen(context, SpetoScreen.helpCenter),
              child: Text(
                'Müşteri Hizmetleri ile Görüş',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Palette.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
