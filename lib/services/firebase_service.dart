import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

      // Enable aggressive local offline persistence & cache for instantaneous 0ms reads
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (settingsErr) {
        debugPrint('[FirebaseService] Firestore settings notice: $settingsErr');
      }

      debugPrint('[FirebaseService] Firebase initialized successfully with offline persistence.');
    } catch (e) {
      debugPrint('[FirebaseService] Firebase initialization notice: $e');
      debugPrint('[FirebaseService] Running with local mock database fallback for Phase 1.');
      _isInitialized = false;
    }
  }
}
