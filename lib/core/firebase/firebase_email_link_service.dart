import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

enum SpetoEmailLinkPurpose { registration, passwordReset }

class SpetoFirebaseEmailLinkService {
  SpetoFirebaseEmailLinkService._();

  static final SpetoFirebaseEmailLinkService instance =
      SpetoFirebaseEmailLinkService._();
  static const bool _emailLinkEnabled = bool.fromEnvironment(
    'SPETO_ENABLE_FIREBASE_EMAIL_LINK',
    defaultValue: false,
  );

  static const String _iosBundleId = 'com.example.speto';
  static const String _androidPackageName = 'com.example.speto';

  bool _initialized = false;

  FirebaseOptions get _options => DefaultFirebaseOptions.currentPlatform;

  bool get isConfigured => _emailLinkEnabled;

  bool get isReady => _initialized && isConfigured;

  Future<void> initialize() async {
    if (_initialized || !isConfigured) {
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: _options);
    }

    _initialized = true;
  }

  Uri buildContinueUri(SpetoEmailLinkPurpose purpose) {
    final String authDomain =
        _options.authDomain ?? '${_options.projectId}.firebaseapp.com';
    final Uri baseUri = Uri.parse('https://$authDomain/auth/email-link');
    return baseUri.replace(
      queryParameters: <String, String>{
        ...baseUri.queryParameters,
        'mode': _purposeToken(purpose),
      },
    );
  }

  Future<void> sendEmailLink({
    required String email,
    required SpetoEmailLinkPurpose purpose,
  }) async {
    await initialize();
    if (!isReady) {
      throw StateError('Firebase Email Link is not configured');
    }

    await FirebaseAuth.instance.sendSignInLinkToEmail(
      email: email.trim(),
      actionCodeSettings: ActionCodeSettings(
        url: buildContinueUri(purpose).toString(),
        handleCodeInApp: true,
        iOSBundleId: _iosBundleId,
        androidPackageName: _androidPackageName,
        androidInstallApp: false,
      ),
    );
  }

  bool isEmailLink(String link) {
    if (!isReady) {
      return false;
    }
    return FirebaseAuth.instance.isSignInWithEmailLink(link.trim());
  }

  Future<void> consumeEmailLink({
    required String email,
    required String emailLink,
  }) async {
    await initialize();
    if (!isReady) {
      throw StateError('Firebase Email Link is not configured');
    }
    await FirebaseAuth.instance.signInWithEmailLink(
      email: email.trim(),
      emailLink: emailLink.trim(),
    );
  }

  Future<void> clearSession() async {
    if (!isReady) {
      return;
    }
    await FirebaseAuth.instance.signOut();
  }

  String purposeLabel(SpetoEmailLinkPurpose purpose) {
    switch (purpose) {
      case SpetoEmailLinkPurpose.registration:
        return 'kayıt doğrulama';
      case SpetoEmailLinkPurpose.passwordReset:
        return 'şifre sıfırlama';
    }
  }

  String _purposeToken(SpetoEmailLinkPurpose purpose) {
    switch (purpose) {
      case SpetoEmailLinkPurpose.registration:
        return 'register';
      case SpetoEmailLinkPurpose.passwordReset:
        return 'password-reset';
    }
  }
}
