import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../providers/providers.dart';
import '../state/app_state.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

/// Centralized authentication service supporting email, Google, and Apple.
class AuthService {
  AuthService(this._ref);

  final Ref _ref;

  SpetoAppState get _appState => _ref.read(appStateProvider);

  /// Email/password sign-in (existing local flow).
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _appState.signIn(email: email, password: password);
  }

  /// Google Sign-In.
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) return false;

      return _appState.signIn(
        email: account.email,
        displayName: account.displayName ?? '',
        avatarUrl: account.photoUrl ?? '',
        trustedProvider: true,
      );
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return false;
    }
  }

  /// Apple Sign-In.
  Future<bool> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String email = credential.email ?? '';
      final String displayName = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].where((s) => s.isNotEmpty).join(' ');

      if (email.isEmpty) return false;

      return _appState.signIn(
        email: email,
        displayName: displayName,
        trustedProvider: true,
      );
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');
      return false;
    }
  }

  /// Sign out from all providers.
  Future<void> signOut() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}

    await _appState.signOut();
  }

  /// Check if Apple Sign-In is available on this device.
  Future<bool> isAppleSignInAvailable() async {
    return await SignInWithApple.isAvailable();
  }
}
