import 'package:flutter/material.dart';

import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/firebase/firebase_email_link_service.dart';

class EmailLinkPendingScreen extends StatelessWidget {
  const EmailLinkPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final bool registrationFlow = appState.pendingRegistration != null;
    final String? email = registrationFlow
        ? appState.pendingRegistration?.email
        : appState.pendingPasswordResetEmail;
    final SpetoEmailLinkPurpose purpose = registrationFlow
        ? SpetoEmailLinkPurpose.registration
        : SpetoEmailLinkPurpose.passwordReset;

    return SpetoScreenScaffold(
      title: 'E-posta Doğrulama',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SpetoCard(
              radius: 28,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF2A1814), Color(0xFF17171B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Palette.orange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: Palette.orange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    registrationFlow
                        ? 'Kayıt doğrulama linki gönderildi'
                        : 'Şifre sıfırlama linki gönderildi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    email == null || email.trim().isEmpty
                        ? 'Mail kutundaki linke tıklayarak işleme devam et.'
                        : '$email adresine gönderilen ${SpetoFirebaseEmailLinkService.instance.purposeLabel(purpose)} linkine tıklayarak devam et.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Palette.soft,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SpetoCard(
              radius: 20,
              color: Palette.cardWarm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Nasıl tamamlanır?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _EmailLinkStep(
                    index: '1',
                    text: 'Mail kutunu aç ve Firebase doğrulama linkine tıkla.',
                  ),
                  const _EmailLinkStep(
                    index: '2',
                    text: 'Link uygulamayı açmazsa tam linki kopyala.',
                  ),
                  const _EmailLinkStep(
                    index: '3',
                    text: 'Aşağıdaki ekrandan linki yapıştır ve devam et.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SpetoPrimaryButton(
              label: 'LİNKİ YAPIŞTIR',
              icon: Icons.link_rounded,
              onTap: () => openScreen(context, SpetoScreen.emailLinkComplete),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: email == null || email.trim().isEmpty
                  ? null
                  : () async {
                      final bool sent = registrationFlow
                          ? await appState.sendRegistrationEmailLink()
                          : await appState.sendPasswordResetEmailLink(email);
                      if (!context.mounted) {
                        return;
                      }
                      if (!sent) {
                        if (registrationFlow) {
                          SpetoToast.show(
                            context,
                            message:
                                'Mail linki şu an gönderilemedi. Kod doğrulamasına geçiliyor.',
                            icon: Icons.info_outline_rounded,
                          );
                          openScreen(context, SpetoScreen.otpVerification);
                          return;
                        }
                        final bool fallback = await appState.requestPasswordReset(
                          email: email,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        if (fallback) {
                          SpetoToast.show(
                            context,
                            message:
                                'Mail link kotası dolu. Şifre yenilemeye kod ile devam ediliyor.',
                            icon: Icons.info_outline_rounded,
                          );
                          openScreen(context, SpetoScreen.otpVerification);
                          return;
                        }
                      }
                      SpetoToast.show(
                        context,
                        message: sent
                            ? 'Link yeniden gönderildi.'
                            : 'Link yeniden gönderilemedi.',
                        icon: sent
                            ? Icons.mark_email_read_outlined
                            : Icons.info_outline_rounded,
                      );
                    },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Linki yeniden gönder'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailLinkStep extends StatelessWidget {
  const _EmailLinkStep({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Palette.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                index,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Palette.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Palette.soft, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
