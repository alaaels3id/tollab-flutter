import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return null;
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBMgapBsiWiMgkx7wgj7XtbnT7LU_Df-n8',
    appId: '1:446314341655:ios:7c98416b5918fa9bdc0352',
    messagingSenderId: '446314341655',
    projectId: 'tollab-de163',
    storageBucket: 'tollab-de163.firebasestorage.app',
    iosBundleId: 'com.alaaelsaid.tollab',
  );
}
