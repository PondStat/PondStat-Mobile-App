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
    apiKey: 'AIzaSyAVRv2GtxhggvYucieAhwTDNC4DpFo_u_g',
    appId: '1:624574025589:web:3d63f7a5409ab901de0d3c',
    messagingSenderId: '624574025589',
    projectId: 'pondstat-7c430',
    authDomain: 'pondstat-7c430.firebaseapp.com',
    storageBucket: 'pondstat-7c430.firebasestorage.app',
    measurementId: 'G-DFP6TSS3Y0',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyASd7yrNQi9LQ0ATNREAAPeoDcHTdIXPvE',
    appId: '1:624574025589:ios:82c3a68720140533de0d3c',
    messagingSenderId: '624574025589',
    projectId: 'pondstat-7c430',
    storageBucket: 'pondstat-7c430.firebasestorage.app',
    iosBundleId: 'com.example.pondstat',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyASd7yrNQi9LQ0ATNREAAPeoDcHTdIXPvE',
    appId: '1:624574025589:ios:82c3a68720140533de0d3c',
    messagingSenderId: '624574025589',
    projectId: 'pondstat-7c430',
    storageBucket: 'pondstat-7c430.firebasestorage.app',
    iosBundleId: 'com.example.pondstat',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAVRv2GtxhggvYucieAhwTDNC4DpFo_u_g',
    appId: '1:624574025589:web:521e4908fc3c1b4bde0d3c',
    messagingSenderId: '624574025589',
    projectId: 'pondstat-7c430',
    authDomain: 'pondstat-7c430.firebaseapp.com',
    storageBucket: 'pondstat-7c430.firebasestorage.app',
    measurementId: 'G-3TYSVV58WW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBfe701Ppxe6QxwxlNi43V_t-pX9-EtFik',
    appId: '1:624574025589:android:0be1efe3c4bfc7c8de0d3c',
    messagingSenderId: '624574025589',
    projectId: 'pondstat-7c430',
    storageBucket: 'pondstat-7c430.firebasestorage.app',
  );
}