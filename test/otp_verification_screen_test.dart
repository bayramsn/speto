import 'package:flutter_test/flutter_test.dart';

import 'package:speto/core/state/app_state.dart';
import 'package:speto/features/auth/otp_verification_screen.dart';

void main() {
  test('release build hides the OTP info card', () {
    expect(
      shouldShowRegistrationOtpCodeInUi(
        usesTestOtpMode: true,
        isReleaseMode: true,
      ),
      isFalse,
    );
  });

  test('debug build shows the OTP info card', () {
    expect(
      shouldShowRegistrationOtpCodeInUi(
        usesTestOtpMode: true,
        isReleaseMode: false,
      ),
      isTrue,
    );
  });

  test('release resend toast does not include the OTP code', () {
    expect(
      resendRegistrationOtpMessage(
        usesTestOtpMode: true,
        testOtpCode: '12345',
        isReleaseMode: true,
      ),
      'Yeni doğrulama kodu gönderildi.',
    );
  });

  test('release invalid code message does not include the OTP code', () {
    expect(
      registrationOtpFailureMessage(
        result: SpetoRegistrationOtpVerificationResult.invalidCode,
        usesTestOtpMode: true,
        testOtpCode: '12345',
        isReleaseMode: true,
      ),
      'Kod doğrulanamadı. Lütfen tekrar deneyin.',
    );
  });

  test('debug invalid code message includes the OTP code', () {
    expect(
      registrationOtpFailureMessage(
        result: SpetoRegistrationOtpVerificationResult.invalidCode,
        usesTestOtpMode: true,
        testOtpCode: '12345',
        isReleaseMode: false,
      ),
      'Kod doğrulanamadı. Test kodu: 12345',
    );
  });
}
