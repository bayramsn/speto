import 'package:flutter_test/flutter_test.dart';

import 'package:speto/core/state/app_state.dart';
import 'package:speto/src/core/bootstrap.dart';
import 'package:speto/src/core/models.dart';

class _ThrowingAuthRepository implements SpetoAuthRepository {
  SpetoRegistrationDraft? draft;

  @override
  Future<void> clearPasswordResetEmail() async {
    throw Exception('expected cleanup failure');
  }

  @override
  Future<void> deleteAccountPassword(String email) async {}

  @override
  Future<String?> readAccountPassword(String email) async => null;

  @override
  Future<String?> readPasswordResetEmail() async => null;

  @override
  Future<SpetoRegistrationDraft?> readRegistrationDraft() async => draft;

  @override
  Future<SpetoSession?> readSession() async => null;

  @override
  Future<void> rememberPasswordResetEmail(String email) async {}

  @override
  Future<void> writeAccountPassword(String email, String password) async {}

  @override
  Future<void> writeRegistrationDraft(SpetoRegistrationDraft? nextDraft) async {
    draft = nextDraft;
  }

  @override
  Future<void> writeSession(SpetoSession? session) async {}
}

void main() {
  test(
    'startRegistration continues when password reset cleanup fails',
    () async {
      final _ThrowingAuthRepository authRepository = _ThrowingAuthRepository();
      final SpetoAppState appState = SpetoAppState(
        authRepository: authRepository,
        commerceRepository: InMemorySpetoCommerceRepository(),
      );

      await appState.startRegistration(
        fullName: 'Debug User',
        email: 'debug@example.com',
        phone: '5551234567',
        password: 'StrongPass123',
      );

      expect(appState.pendingRegistration, isNotNull);
      expect(appState.pendingRegistration!.email, 'debug@example.com');
      expect(authRepository.draft, isNotNull);
    },
  );
}
