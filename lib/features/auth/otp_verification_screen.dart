import 'package:flutter/foundation.dart' show kReleaseMode, visibleForTesting;
import 'package:flutter/material.dart';

import '../../core/data/default_data.dart';
import '../../core/navigation/navigator.dart';
import '../../core/navigation/screen_enum.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/palette.dart';
import '../../shared/widgets/widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _code = '';

  void _appendDigit(String digit) {
    if (_code.length >= 5) {
      return;
    }
    setState(() => _code = '$_code$digit');
  }

  void _removeDigit() {
    if (_code.isEmpty) {
      return;
    }
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  Future<void> _resendCode({
    required bool isPasswordResetFlow,
    required SpetoAppState appState,
  }) async {
    setState(() => _code = '');
    if (isPasswordResetFlow) {
      final String? resetEmail = appState.pendingPasswordResetEmail;
      if (resetEmail != null && resetEmail.trim().isNotEmpty) {
        await appState.requestPasswordReset(email: resetEmail);
      }
    }
    if (!mounted) {
      return;
    }
    SpetoToast.show(
      context,
      message: _resendOtpMessage(
        usesTestOtpMode: appState.usesTestOtpMode,
        testOtpCode: appState.testOtpCode,
      ),
      icon: isPasswordResetFlow
          ? Icons.mark_email_read_outlined
          : Icons.sms_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SpetoAppState appState = SpetoAppScope.of(context);
    final String? resetEmail = appState.pendingPasswordResetEmail;
    final bool isPasswordResetFlow =
        appState.pendingRegistration == null &&
        resetEmail != null &&
        resetEmail.trim().isNotEmpty;
    final List<String> digits = List<String>.generate(
      5,
      (int index) => index < _code.length ? _code[index] : '',
    );
    return SpetoScreenScaffold(
      title: isPasswordResetFlow ? 'E-Posta Kodunu Girin' : 'Kodu Girin',
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                children: <Widget>[
                  SpetoCard(
                    radius: 24,
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF2A1814), Color(0xFF17171B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Palette.red.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            isPasswordResetFlow
                                ? Icons.mark_email_unread_outlined
                                : Icons.verified_user_outlined,
                            color: Palette.red,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isPasswordResetFlow
                              ? 'Şifre sıfırlama doğrulaması'
                              : 'Hesabını doğrula',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isPasswordResetFlow
                              ? '${maskEmailAddress(resetEmail)} için doğrulama kodunu girerek yeni şifre oluştur.'
                              : 'Doğrulama kodunu girerek hesabınızı tamamlayın.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Palette.soft, height: 1.6),
                        ),
                        if (isPasswordResetFlow) ...<Widget>[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              maskEmailAddress(resetEmail),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Palette.orange,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPasswordResetFlow
                        ? 'Kod doğrulanınca yeni şifrenizi güvenle belirleyebilirsiniz.'
                        : 'Doğrulama kodunu girerek kaydı tamamlayın.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Palette.soft,
                      height: 1.6,
                    ),
                  ),
                  if (_shouldShowOtpCodeCard(
                    usesTestOtpMode: appState.usesTestOtpMode,
                  )) ...<Widget>[
                    const SizedBox(height: 16),
                    SpetoCard(
                      radius: 16,
                      color: Palette.cardWarm,
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.bug_report_outlined,
                            color: Palette.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Test modu aktif. Doğrulama kodu: ${appState.testOtpCode}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Palette.soft,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: digits.map((String digit) {
                      return Container(
                        width: 56,
                        height: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: digit.isEmpty
                              ? Palette.card
                              : Palette.cardWarm,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: digit.isEmpty
                                ? Colors.white.withValues(alpha: 0.08)
                                : Palette.red,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            digit,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SpetoCard(
                    radius: 16,
                    color: Palette.cardWarm,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.timer_outlined,
                          color: Palette.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '00:45',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _resendCode(
                      isPasswordResetFlow: isPasswordResetFlow,
                      appState: appState,
                    ),
                    child: Text(
                      'Kodu tekrar gönder',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Palette.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SpetoPrimaryButton(
                    label: 'ONAYLA',
                    onTap: () async {
                      if (_code.length < 5) {
                        SpetoToast.show(
                          context,
                          message: 'Doğrulama kodunu girin.',
                          icon: Icons.info_outline_rounded,
                        );
                        return;
                      }
                      if (!isPasswordResetFlow) {
                        final SpetoRegistrationOtpVerificationResult result =
                            await appState.verifyOtpCode(_code);
                        if (result !=
                            SpetoRegistrationOtpVerificationResult.verified) {
                          if (!context.mounted) {
                            return;
                          }
                          final String message =
                              result ==
                                      SpetoRegistrationOtpVerificationResult
                                          .unavailable &&
                                  appState.pendingRegistration == null
                              ? 'Aktif bir doğrulama isteği bulunamadı.'
                              : _registrationOtpFailureMessage(
                                  result: result,
                                  usesTestOtpMode: appState.usesTestOtpMode,
                                  testOtpCode: appState.testOtpCode,
                                );
                          SpetoToast.show(
                            context,
                            message: message,
                            icon: Icons.info_outline_rounded,
                          );
                          return;
                        }
                        if (!context.mounted) {
                          return;
                        }
                        openRootScreen(context, SpetoScreen.home);
                        return;
                      } else if (isPasswordResetFlow) {
                        final bool verified = await appState
                            .verifyPasswordResetOtp(_code);
                        if (!verified) {
                          if (!context.mounted) {
                            return;
                          }
                          SpetoToast.show(
                            context,
                            message:
                                'Kod doğrulanamadı. Yeni kod isteyip tekrar deneyin.',
                            icon: Icons.info_outline_rounded,
                          );
                          return;
                        }
                        if (!context.mounted) {
                          return;
                        }
                        openScreen(context, SpetoScreen.resetPassword);
                        return;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: List<Widget>.generate(4, (int row) {
                final List<String> keys = row == 3
                    ? <String>['', '0', '\u232B']
                    : <String>[
                        '${row * 3 + 1}',
                        '${row * 3 + 2}',
                        '${row * 3 + 3}',
                      ];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: keys.map((String key) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: key.isEmpty
                              ? null
                              : key == '\u232B'
                              ? _removeDigit
                              : () => _appendDigit(key),
                          child: Container(
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: key.isEmpty
                                  ? Colors.transparent
                                  : Palette.card,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: key.isEmpty
                                  ? const SizedBox.shrink()
                                  : Text(
                                      key,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
bool shouldShowRegistrationOtpCodeInUi({
  required bool usesTestOtpMode,
  bool isReleaseMode = kReleaseMode,
}) {
  return usesTestOtpMode && !isReleaseMode;
}

@visibleForTesting
String resendRegistrationOtpMessage({
  required bool usesTestOtpMode,
  required String testOtpCode,
  bool isReleaseMode = kReleaseMode,
}) {
  if (shouldShowRegistrationOtpCodeInUi(
    usesTestOtpMode: usesTestOtpMode,
    isReleaseMode: isReleaseMode,
  )) {
    return 'Yeni test doğrulama kodu gönderildi. Kod: $testOtpCode';
  }
  return 'Yeni doğrulama kodu gönderildi.';
}

@visibleForTesting
String registrationOtpFailureMessage({
  required SpetoRegistrationOtpVerificationResult result,
  required bool usesTestOtpMode,
  required String testOtpCode,
  bool isReleaseMode = kReleaseMode,
}) {
  return switch (result) {
    SpetoRegistrationOtpVerificationResult.invalidCode =>
      shouldShowRegistrationOtpCodeInUi(
            usesTestOtpMode: usesTestOtpMode,
            isReleaseMode: isReleaseMode,
          )
          ? 'Kod doğrulanamadı. Test kodu: $testOtpCode'
          : 'Kod doğrulanamadı. Lütfen tekrar deneyin.',
    SpetoRegistrationOtpVerificationResult.emailAlreadyRegistered =>
      'Bu e-posta zaten kayıtlı. Giriş yapmayı deneyin veya farklı bir e-posta kullanın.',
    SpetoRegistrationOtpVerificationResult.unavailable =>
      'Kayıt tamamlanamadı. Lütfen tekrar deneyin.',
    SpetoRegistrationOtpVerificationResult.verified => '',
  };
}

bool _shouldShowOtpCodeCard({required bool usesTestOtpMode}) {
  return shouldShowRegistrationOtpCodeInUi(usesTestOtpMode: usesTestOtpMode);
}

String _resendOtpMessage({
  required bool usesTestOtpMode,
  required String testOtpCode,
}) {
  return resendRegistrationOtpMessage(
    usesTestOtpMode: usesTestOtpMode,
    testOtpCode: testOtpCode,
  );
}

String _registrationOtpFailureMessage({
  required SpetoRegistrationOtpVerificationResult result,
  required bool usesTestOtpMode,
  required String testOtpCode,
}) {
  return registrationOtpFailureMessage(
    result: result,
    usesTestOtpMode: usesTestOtpMode,
    testOtpCode: testOtpCode,
  );
}
