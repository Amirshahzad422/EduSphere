// File generated for Firebase initialization.
// Update these values with your actual Firebase Console project settings if connecting live.

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
    apiKey: 'AIzaSyBt9iDoO1PrxrDYON61pv8FX5B0E79ZSBs',
    appId: '1:1078631241013:web:4564818a97628894aea87c',
    messagingSenderId: '1078631241013',
    projectId: 'edusphere-ae8ed',
    authDomain: 'edusphere-ae8ed.firebaseapp.com',
    storageBucket: 'edusphere-ae8ed.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgyLQkJb-MHlIJAlrq4_3AJB0yroaxqVY',
    appId: '1:1078631241013:android:44fac264c23f1ac1aea87c',
    messagingSenderId: '1078631241013',
    projectId: 'edusphere-ae8ed',
    storageBucket: 'edusphere-ae8ed.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemo-EduSphere-IOS-ApiKey-2026',
    appId: '1:123456789012:ios:edusphereiosapp001',
    messagingSenderId: '123456789012',
    projectId: 'edusphere-demo-app',
    storageBucket: 'edusphere-demo-app.appspot.com',
    iosBundleId: 'com.example.edusphere',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDemo-EduSphere-MacOS-ApiKey-2026',
    appId: '1:123456789012:ios:eduspheremacosapp001',
    messagingSenderId: '123456789012',
    projectId: 'edusphere-demo-app',
    storageBucket: 'edusphere-demo-app.appspot.com',
    iosBundleId: 'com.example.edusphere',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDemo-EduSphere-Windows-ApiKey-2026',
    appId: '1:123456789012:web:eduspherewindows001',
    messagingSenderId: '123456789012',
    projectId: 'edusphere-demo-app',
    storageBucket: 'edusphere-demo-app.appspot.com',
  );
}
