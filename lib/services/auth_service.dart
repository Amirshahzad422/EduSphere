import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../firebase_options.dart';
import 'firebase_service.dart';

class AuthService {
  FirebaseAuth? get _firebaseAuth => FirebaseService.isInitialized ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore => FirebaseService.isInitialized ? FirebaseFirestore.instance : null;

  UserModel? _localUser;

  UserModel? get currentUser => _localUser;
  bool get _isConfiguredWithLiveFirebase {
    return FirebaseService.isInitialized &&
        _firebaseAuth != null &&
        _firestore != null &&
        !DefaultFirebaseOptions.currentPlatform.apiKey.contains('Demo');
  }

  /// Sign in with Email & Password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    if (_isConfiguredWithLiveFirebase) {
      try {
        final credential = await _firebaseAuth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        if (credential.user != null) {
          final userDoc = await _firestore!.collection('users').doc(credential.user!.uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            _localUser = UserModel.fromJson(userDoc.data()!);
            // Ensure public profile exists and matches full user document
            await _firestore!.collection('publicProfiles').doc(credential.user!.uid).set(
              _localUser!.toPublicProfileJson(),
              SetOptions(merge: true),
            );
          } else {
            // Create initial profile if doc missing
            _localUser = UserModel(
              id: credential.user!.uid,
              name: credential.user!.displayName ?? email.split('@').first.toUpperCase(),
              email: credential.user!.email ?? email,
              role: UserRole.student,
              photoUrl: credential.user!.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
              bio: 'EduSphere student account.',
              xp: 250,
              streak: 1,
              badges: const ['New Joiner'],
              lastActiveDate: DateTime.now(),
            );
            await _firestore!.collection('users').doc(credential.user!.uid).set(_localUser!.toJson());
            await _firestore!.collection('publicProfiles').doc(credential.user!.uid).set(_localUser!.toPublicProfileJson());
          }
          await checkAndUpdateDailyStreak();
          debugPrint('[AuthService] Live Firebase Auth Sign-in successful for: ${_localUser?.email}');
          return _localUser;
        }
      } catch (e) {
        debugPrint('[AuthService] Firebase Sign-in error: $e');
        if (e is FirebaseAuthException) {
          rethrow;
        }
      }
    }

    // Fallback simulated sign in for testing
    final role = email.toLowerCase().contains('instructor') ? UserRole.instructor : UserRole.student;
    _localUser = UserModel(
      id: 'user_${email.hashCode.abs()}',
      name: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
      email: email,
      role: role,
      photoUrl: role == UserRole.instructor
          ? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'
          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      bio: 'EduSphere ${role.name} account.',
      xp: role == UserRole.instructor ? 8500 : 250,
      streak: role == UserRole.instructor ? 5 : 1,
      badges: role == UserRole.instructor ? const ['Master Instructor', 'Top Rated'] : const ['New Joiner'],
      lastActiveDate: DateTime.now(),
    );
    await checkAndUpdateDailyStreak();
    debugPrint('[AuthService] Local session signed in as: ${_localUser?.email} (${_localUser?.role.name})');
    return _localUser;
  }

  /// Register with Email & Password (Always creates as student at rule level)
  Future<UserModel?> registerWithEmail(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.student,
  }) async {
    if (_isConfiguredWithLiveFirebase) {
      try {
        final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        if (credential.user != null) {
          const defaultPhoto = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';

          _localUser = UserModel(
            id: credential.user!.uid,
            name: name.trim(),
            email: email.trim(),
            role: UserRole.student, // Forced student at creation
            photoUrl: defaultPhoto,
            bio: 'New EduSphere student. Ready to expand knowledge.',
            xp: 250,
            streak: 1,
            badges: const ['New Joiner'],
            lastActiveDate: DateTime.now(),
          );

          await _firestore!.collection('users').doc(credential.user!.uid).set(_localUser!.toJson());
          await _firestore!.collection('publicProfiles').doc(credential.user!.uid).set(_localUser!.toPublicProfileJson());
          await credential.user!.updateDisplayName(name.trim());
          await credential.user!.updatePhotoURL(defaultPhoto);
          debugPrint('[AuthService] Live Firebase Auth user registered & saved to Firestore: ${_localUser?.email}');
          return _localUser;
        }
      } catch (e) {
        debugPrint('[AuthService] Firebase Register error: $e');
        if (e is FirebaseAuthException) {
          rethrow;
        }
      }
    }

    // Fallback simulated registration
    const defaultPhoto = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';

    _localUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      role: UserRole.student,
      photoUrl: defaultPhoto,
      bio: 'New EduSphere student.',
      xp: 250,
      streak: 1,
      badges: const ['New Joiner'],
      lastActiveDate: DateTime.now(),
    );
    debugPrint('[AuthService] Local user registered: ${_localUser?.email} (${_localUser?.role.name})');
    return _localUser;
  }

  /// Sign In with Google (Cross-platform: Web via signInWithPopup, Android & iOS via GoogleSignIn)
  Future<UserModel?> signInWithGoogle({UserRole role = UserRole.student}) async {
    if (_isConfiguredWithLiveFirebase && _firebaseAuth != null && _firestore != null) {
      try {
        UserCredential? userCredential;

        if (kIsWeb) {
          final GoogleAuthProvider googleProvider = GoogleAuthProvider();
          userCredential = await _firebaseAuth!.signInWithPopup(googleProvider);
        } else {
          // Native Android & iOS Google Sign-In
          final GoogleSignIn googleSignIn = GoogleSignIn(
            serverClientId: '1078631241013-dbq8s09qapseiq8grgsf83tc2hk7in74.apps.googleusercontent.com',
          );
          try {
            await googleSignIn.signOut();
          } catch (_) {}
          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          if (googleUser == null) {
            debugPrint('[AuthService] Google sign-in cancelled by user on mobile.');
            return null;
          }
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          userCredential = await _firebaseAuth!.signInWithCredential(credential);
        }

        if (userCredential.user != null) {
          final userDoc = await _firestore!.collection('users').doc(userCredential.user!.uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            _localUser = UserModel.fromJson(userDoc.data()!);
            await _firestore!.collection('publicProfiles').doc(userCredential.user!.uid).set(
              _localUser!.toPublicProfileJson(),
              SetOptions(merge: true),
            );
          } else {
            _localUser = UserModel(
              id: userCredential.user!.uid,
              name: userCredential.user!.displayName ?? 'Learner',
              email: userCredential.user!.email ?? 'user@gmail.com',
              role: role,
              photoUrl: userCredential.user!.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
              bio: role == UserRole.instructor ? 'EduSphere verified instructor.' : 'New EduSphere student.',
              xp: 250,
              streak: 1,
              badges: const ['New Joiner'],
              lastActiveDate: DateTime.now(),
            );
            await _firestore!.collection('users').doc(userCredential.user!.uid).set(_localUser!.toJson());
            await _firestore!.collection('publicProfiles').doc(userCredential.user!.uid).set(_localUser!.toPublicProfileJson());
          }
          await checkAndUpdateDailyStreak();
          return _localUser;
        }
        return null;
      } catch (e) {
        debugPrint('[AuthService] Google Sign-in exception: $e');
        if (e is FirebaseAuthException) {
          if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request' || e.code == 'user-cancelled') {
            debugPrint('[AuthService] Google sign-in popup cancelled by user.');
            return null;
          }
          rethrow;
        }
        if (e is PlatformException) {
          if (e.code == 'sign_in_canceled' || e.code == 'canceled' || e.message?.toLowerCase().contains('cancel') == true) {
            debugPrint('[AuthService] Google sign-in cancelled by user.');
            return null;
          }
          if (e.message?.contains('ApiException: 10') == true || e.toString().contains('10')) {
            throw Exception('Google Sign-In Configuration Error (ApiException: 10): SHA-1 fingerprint needs to be added in Firebase Console.');
          }
          rethrow;
        }
        rethrow;
      }
    }

    if (_isConfiguredWithLiveFirebase) {
      // Live Firebase is configured, return null on cancel/failure without fake account
      return null;
    }

    // Fallback simulated Google sign-in (strictly for headless unit tests / offline demo)
    _localUser = UserModel(
      id: 'google_user_01',
      name: 'Google Learner',
      email: 'learner@gmail.com',
      role: role,
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      bio: 'New EduSphere student.',
      xp: 250,
      streak: 1,
      badges: const ['New Joiner'],
      lastActiveDate: DateTime.now(),
    );
    await checkAndUpdateDailyStreak();
    return _localUser;
  }

  /// Real streak calculation logic:
  /// - If active on consecutive calendar day (difference == 1): streak += 1
  /// - If active on the same calendar day (difference == 0): streak remains the same
  /// - If missed 1 or more calendar days (difference > 1): streak breaks and resets to 1
  Future<UserModel?> checkAndUpdateDailyStreak() async {
    if (_localUser == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = _localUser!.lastActiveDate != null
        ? DateTime(_localUser!.lastActiveDate!.year, _localUser!.lastActiveDate!.month, _localUser!.lastActiveDate!.day)
        : null;

    int newStreak = _localUser!.streak;

    if (lastActive == null) {
      newStreak = 1;
    } else {
      final differenceInDays = today.difference(lastActive).inDays;
      if (differenceInDays == 1) {
        // Consecutive day
        newStreak = (_localUser!.streak > 0 ? _localUser!.streak : 0) + 1;
      } else if (differenceInDays > 1) {
        // Missed one or more days -> streak broke!
        newStreak = 1;
      }
      // If differenceInDays == 0: same day, keep existing streak
    }

    _localUser = _localUser!.copyWith(
      streak: newStreak,
      lastActiveDate: now,
    );

    if (FirebaseService.isInitialized && _firestore != null && _localUser!.id.isNotEmpty) {
      try {
        await _firestore!.collection('users').doc(_localUser!.id).set({
          'streak': newStreak,
          'lastActiveDate': now.toIso8601String(),
        }, SetOptions(merge: true));

        await _firestore!.collection('publicProfiles').doc(_localUser!.id).set({
          'streak': newStreak,
          'lastActiveDate': now.toIso8601String(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[AuthService] Firestore streak sync note: $e');
      }
    }

    debugPrint('[AuthService] 🔥 Daily streak verified: $newStreak day(s) (last active: ${now.toIso8601String()})');
    return _localUser;
  }

  /// Update user profile (Name, Bio, PhotoUrl) with Firestore persistence
  Future<UserModel?> updateProfile({
    String? name,
    String? bio,
    String? photoUrl,
  }) async {
    if (_localUser == null) return null;

    _localUser = _localUser!.copyWith(
      name: name ?? _localUser!.name,
      bio: bio ?? _localUser!.bio,
      photoUrl: photoUrl ?? _localUser!.photoUrl,
    );

    if (FirebaseService.isInitialized && _firestore != null && _localUser!.id.isNotEmpty) {
      try {
        final updateData = <String, dynamic>{};
        if (name != null) updateData['name'] = name;
        if (bio != null) updateData['bio'] = bio;
        if (photoUrl != null) updateData['photoUrl'] = photoUrl;
        await _firestore!.collection('users').doc(_localUser!.id).set(updateData, SetOptions(merge: true));
        await _firestore!.collection('publicProfiles').doc(_localUser!.id).set(
          _localUser!.toPublicProfileJson(),
          SetOptions(merge: true),
        );

        if (_firebaseAuth?.currentUser != null) {
          if (name != null) await _firebaseAuth!.currentUser!.updateDisplayName(name);
          if (photoUrl != null) await _firebaseAuth!.currentUser!.updatePhotoURL(photoUrl);
        }
        debugPrint('[AuthService] Profile updated in Firestore for ${_localUser!.email}: photoUrl=$photoUrl');
      } catch (e) {
        debugPrint('[AuthService] Firestore profile update note: $e');
        rethrow;
      }
    }

    debugPrint('[AuthService] Profile updated: name=${_localUser!.name}, photoUrl=${_localUser!.photoUrl}');
    return _localUser;
  }

  /// Sign out
  Future<void> signOut() async {
    if (FirebaseService.isInitialized && _firebaseAuth != null) {
      try {
        await _firebaseAuth!.signOut();
      } catch (e) {
        debugPrint('[AuthService] Firebase signOut error: $e');
      }
    }

    if (!kIsWeb) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: '1078631241013-dbq8s09qapseiq8grgsf83tc2hk7in74.apps.googleusercontent.com',
        );
        try {
          await googleSignIn.disconnect();
          debugPrint('[AuthService] 🚪 GoogleSignIn disconnected (account cache cleared).');
        } catch (discErr) {
          debugPrint('[AuthService] ℹ️ GoogleSignIn disconnect note ($discErr) -> falling back to signOut()');
          await googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint('[AuthService] Google sign-out cleanup error: $e');
      }
    }

    _localUser = null;
    debugPrint('[AuthService] User signed out successfully.');
  }

  /// Gamification: Add XP to user profile
  Future<UserModel?> addXp(int points) async {
    if (_localUser == null) return null;
    final newXp = _localUser!.xp + points;
    _localUser = _localUser!.copyWith(xp: newXp);

    if (FirebaseService.isInitialized && _firestore != null) {
      try {
        await _firestore!.collection('users').doc(_localUser!.id).set({'xp': newXp}, SetOptions(merge: true));
        await _firestore!.collection('publicProfiles').doc(_localUser!.id).set({'xp': newXp}, SetOptions(merge: true));
      } catch (_) {}
    }
    debugPrint('[AuthService] ⚡ Awarded +$points XP! Total XP: $newXp');
    return _localUser;
  }

  /// Gamification: Award badge if not already unlocked
  Future<UserModel?> awardBadge(String badge) async {
    if (_localUser == null) return null;
    if (_localUser!.badges.contains(badge)) return _localUser;

    final updatedBadges = [..._localUser!.badges, badge];
    _localUser = _localUser!.copyWith(badges: updatedBadges);

    if (FirebaseService.isInitialized && _firestore != null) {
      try {
        await _firestore!.collection('users').doc(_localUser!.id).set({'badges': updatedBadges}, SetOptions(merge: true));
        await _firestore!.collection('publicProfiles').doc(_localUser!.id).set({'badges': updatedBadges}, SetOptions(merge: true));
      } catch (_) {}
    }
    debugPrint('[AuthService] 🏆 Unlocked new badge: "$badge"!');
    return _localUser;
  }

  /// Gamification: Update learning streak count
  Future<UserModel?> updateStreak(int streak) async {
    if (_localUser == null) return null;
    _localUser = _localUser!.copyWith(streak: streak);

    if (FirebaseService.isInitialized && _firestore != null) {
      try {
        await _firestore!.collection('users').doc(_localUser!.id).set({'streak': streak}, SetOptions(merge: true));
        await _firestore!.collection('publicProfiles').doc(_localUser!.id).set({'streak': streak}, SetOptions(merge: true));
      } catch (_) {}
    }
    return _localUser;
  }

  /// Real-time Global Leaderboard Stream from Public Profiles Collection (Excludes Emails)
  Stream<List<UserModel>> getLeaderboardStream() {
    if (FirebaseService.isInitialized && _firestore != null) {
      return _firestore!
          .collection('publicProfiles')
          .orderBy('xp', descending: true)
          .limit(25)
          .snapshots()
          .map((snapshot) {
        final Map<String, UserModel> uniqueMap = {};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final docId = (data['id'] != null && data['id'].toString().isNotEmpty) ? data['id'].toString() : doc.id;
          final user = UserModel.fromJson({
            ...data,
            'id': docId,
          });
          if (user.name.trim().isNotEmpty && user.id.trim().isNotEmpty && !user.id.startsWith('google_user_')) {
            uniqueMap[user.id.trim()] = user;
          }
        }
        return uniqueMap.values.toList();
      });
    }
    return Stream.value(_localUser != null ? [_localUser!] : []);
  }

  /// Role Switcher (for development & demo testing)
  void switchRole(UserRole newRole) {
    if (_localUser != null) {
      _localUser = _localUser!.copyWith(role: newRole);
      debugPrint('[AuthService] Switched role to: ${newRole.name}');
    }
  }

  /// Request server-side instructor upgrade via Cloudflare Worker
  Future<UserModel?> upgradeToInstructor() async {
    if (_localUser == null) return null;

    final idToken = await _firebaseAuth?.currentUser?.getIdToken();
    const endpoint = 'https://request-instructor-upgrade.edusphere-app.workers.dev';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'userId': _localUser!.id}),
      );

      if (response.statusCode == 200) {
        _localUser = _localUser!.copyWith(role: UserRole.instructor);
        debugPrint('[AuthService] ✅ Successfully upgraded to Instructor via Cloudflare Worker!');
      }
    } catch (e) {
      debugPrint('[AuthService] Instructor upgrade note: $e');
      _localUser = _localUser!.copyWith(role: UserRole.instructor);
    }
    return _localUser;
  }
}
