// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAaz4INbTZb9ElpquMXFvhEYBDej3FSRvY',
    appId: '1:1055222295322:web:e5143e1eaa602baae69aa3',
    messagingSenderId: '1055222295322',
    projectId: 'budgie-final-year',
    authDomain: 'budgie-final-year.firebaseapp.com',
    storageBucket: 'budgie-final-year.firebasestorage.app',
    measurementId: 'G-ZXXFHSGR9W',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBGmEIMbXgK86msSpvt_BDVAN_zfvp3e70',
    appId: '1:1055222295322:android:c3d686c7454569fee69aa3',
    messagingSenderId: '1055222295322',
    projectId: 'budgie-final-year',
    storageBucket: 'budgie-final-year.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCA3w2CNL5kCx7QhUghoRFOj39e7R_Eoxk',
    appId: '1:1055222295322:ios:e98cc74b192beaf3e69aa3',
    messagingSenderId: '1055222295322',
    projectId: 'budgie-final-year',
    storageBucket: 'budgie-final-year.firebasestorage.app',
    androidClientId: '1055222295322-k80e7oskgl4ma1f57bv3c86errpbm8d4.apps.googleusercontent.com',
    iosClientId: '1055222295322-cqegjfgvn826g8pc01bqko1h1rv9m5vf.apps.googleusercontent.com',
    iosBundleId: 'com.kai.budgie',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCA3w2CNL5kCx7QhUghoRFOj39e7R_Eoxk',
    appId: '1:1055222295322:ios:e98cc74b192beaf3e69aa3',
    messagingSenderId: '1055222295322',
    projectId: 'budgie-final-year',
    storageBucket: 'budgie-final-year.firebasestorage.app',
    androidClientId: '1055222295322-k80e7oskgl4ma1f57bv3c86errpbm8d4.apps.googleusercontent.com',
    iosClientId: '1055222295322-cqegjfgvn826g8pc01bqko1h1rv9m5vf.apps.googleusercontent.com',
    iosBundleId: 'com.kai.budgie',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAaz4INbTZb9ElpquMXFvhEYBDej3FSRvY',
    appId: '1:1055222295322:web:7db75608f1d6484ee69aa3',
    messagingSenderId: '1055222295322',
    projectId: 'budgie-final-year',
    authDomain: 'budgie-final-year.firebaseapp.com',
    storageBucket: 'budgie-final-year.firebasestorage.app',
    measurementId: 'G-14GM0SSEEG',
  );

}