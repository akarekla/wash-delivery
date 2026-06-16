// Generated from google-services.json for project washer-app-b93c2
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return apple;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return android; // same project, desktop testing only
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCQ8YH8xH0kut2cpG7xjKooh0jGiVhPZgM',
    appId: '1:689483175979:android:f87777cd3772f75666b26e',
    messagingSenderId: '689483175979',
    projectId: 'washer-app-b93c2',
    storageBucket: 'washer-app-b93c2.firebasestorage.app',
  );

  // Reuses Android credentials for Mac/iOS dev testing.
  // For production iOS, add a real iOS app in Firebase Console.
  static const FirebaseOptions apple = FirebaseOptions(
    apiKey: 'AIzaSyCQ8YH8xH0kut2cpG7xjKooh0jGiVhPZgM',
    appId: '1:689483175979:android:f87777cd3772f75666b26e',
    messagingSenderId: '689483175979',
    projectId: 'washer-app-b93c2',
    storageBucket: 'washer-app-b93c2.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCQ8YH8xH0kut2cpG7xjKooh0jGiVhPZgM',
    appId: '1:689483175979:android:f87777cd3772f75666b26e',
    messagingSenderId: '689483175979',
    projectId: 'washer-app-b93c2',
    storageBucket: 'washer-app-b93c2.firebasestorage.app',
    authDomain: 'washer-app-b93c2.firebaseapp.com',
  );
}
