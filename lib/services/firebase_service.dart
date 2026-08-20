import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint('[FirebaseService] Firebase initialized successfully.');
    } catch (e) {
      debugPrint('[FirebaseService] Firebase initialization notice: $e');
      debugPrint('[FirebaseService] Running with local mock database fallback for Phase 1.');
      _isInitialized = false;
    }
  }
}
