/// Firebase Configuration
/// 
/// This file contains Firebase initialization and configuration
/// Uses only FREE tier features (Spark plan)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initialize Firebase
/// 
/// Call this in main() before runApp()
/// 
/// Note: You need to:
/// 1. Create Firebase project at https://console.firebase.google.com
/// 2. Add Android app to Firebase project
/// 3. Download google-services.json
/// 4. Place in android/app/
/// 5. Follow Firebase Flutter setup guide
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // In development, you might want to continue without Firebase
    // In production, this should throw
    rethrow;
  }
}

/// Default Firebase Options
/// 
/// IMPORTANT: Before using Firebase, you MUST:
/// 
/// 1. Create Firebase project at https://console.firebase.google.com
/// 2. Add Android app to Firebase project
/// 3. Download google-services.json
/// 4. Place in android/app/
/// 5. Run: flutterfire configure
///    This will automatically generate FirebaseOptions
/// 
/// OR manually configure:
/// - Get values from Firebase Console > Project Settings
/// - Replace placeholders below
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web platform not supported yet');
    }
    
    // Android configuration
    // IMPORTANT: Replace with your actual Firebase configuration
    // Get values from Firebase Console > Project Settings > Your apps
    // OR use flutterfire configure command to auto-generate
    return const FirebaseOptions(
      apiKey: 'YOUR_API_KEY_HERE', // Replace with your Firebase API key
      appId: 'YOUR_APP_ID_HERE', // Replace with your app ID
      messagingSenderId: 'YOUR_SENDER_ID_HERE', // Replace with your sender ID
      projectId: 'YOUR_PROJECT_ID_HERE', // Replace with your project ID
      storageBucket: 'YOUR_STORAGE_BUCKET_HERE', // Replace with your storage bucket
    );
  }
}
