import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBBCciI56wY8x-W_5VZVjGVANc8EZDJBCg',
    appId: '1:296155447730:web:d76720cabf64c665b324ab',
    messagingSenderId: '296155447730',
    projectId: 'speto-4068',
    authDomain: 'speto-4068.firebaseapp.com',
    storageBucket: 'speto-4068.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0go_dDxL39FXZP9LH2aywTOzfCVGHfr8',
    appId: '1:296155447730:android:95f3e30aaa745810b324ab',
    messagingSenderId: '296155447730',
    projectId: 'speto-4068',
    storageBucket: 'speto-4068.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCQVrIfmSneUKwNsoR4pL-b6dQA7K7KiOA',
    appId: '1:296155447730:ios:937f4cacdecee550b324ab',
    messagingSenderId: '296155447730',
    projectId: 'speto-4068',
    storageBucket: 'speto-4068.firebasestorage.app',
    iosBundleId: 'com.example.speto',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCQVrIfmSneUKwNsoR4pL-b6dQA7K7KiOA',
    appId: '1:296155447730:ios:937f4cacdecee550b324ab',
    messagingSenderId: '296155447730',
    projectId: 'speto-4068',
    storageBucket: 'speto-4068.firebasestorage.app',
    iosBundleId: 'com.example.speto',
  );
}
