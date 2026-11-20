// File configured for Dressy.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'config/ps_config.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: PsConfig.androidApiKey,
    appId: PsConfig.androidGoogleAppId,
    messagingSenderId: PsConfig.androidGcmSenderId,
    projectId: PsConfig.androidProjectId,
    databaseURL: PsConfig.androidDatabaseUrl,
    storageBucket: 'dressydz.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: PsConfig.iosApiKey,
    appId: PsConfig.iosGoogleAppId,
    messagingSenderId: PsConfig.iosGcmSenderId,
    projectId: PsConfig.iosProjectId,
    databaseURL: PsConfig.iosDatabaseUrl,
    storageBucket: 'dressydz.firebasestorage.app',
    iosBundleId: 'com.dressy.app',
  );
}
