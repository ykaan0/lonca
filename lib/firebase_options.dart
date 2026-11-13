import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions bu platform için yapılandırılmadı.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCqbZghW0T6O7ulu5YZK8mOuL3QcJ1IbYY',
    appId: '1:740836414182:android:55b94c6faedbceadfce127',
    messagingSenderId: '740836414182',
    projectId: 'grupprojesi-d8c8d',
    storageBucket: 'grupprojesi-d8c8d.firebasestorage.app',
  );
}
