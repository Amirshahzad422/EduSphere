import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../firebase_options.dart';
import 'firebase_service.dart';

class AuthService {
  FirebaseAuth? get _firebaseAuth => FirebaseService.isInitialized ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore => FirebaseService.isInitialized ? FirebaseFirestore.instance : null;

  UserModel? _localUser = const UserModel(
    id: 'user_demo_01',
    name: 'Alex Morgan',
    email: 'alex.morgan@edusphere.io',
    role: UserRole.student,
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    bio: 'Lifelong learner & aspiring full-stack mobile developer.',
    xp: 2450,
    streak: 12,
    badges: ['Fast Learner', 'Quiz Master', 'Top Contributor', '7-Day Streak'],
  );

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
          } else {
            // Create initial profile if doc missing
            _localUser = UserModel(
              id: credential.user!.uid,
              name: credential.user!.displayName ?? email.split('@').first.toUpperCase(),
              email: credential.user!.email ?? email,
              role: UserRole.student,
              photoUrl: credential.user!.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
              bio: 'EduSphere student account.',
              xp: 500,
              streak: 3,
              badges: ['Early Explorer'],
            );
            await _firestore!.collection('users').doc(credential.user!.uid).set(_localUser!.toJson());
          }
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
      xp: role == UserRole.instructor ? 8500 : 1200,
      streak: 5,
      badges: role == UserRole.instructor ? ['Master Instructor', 'Top Rated'] : ['Early Adopter', 'Code Explorer'],
    );
    debugPrint('[AuthService] Local session signed in as: ${_localUser?.email} (${_localUser?.role.name})');
    return _localUser;
  }

  /// Register with Email, Password and Role
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
          final defaultPhoto = role == UserRole.instructor
              ? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'
              : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';

          _localUser = UserModel(
            id: credential.user!.uid,
            name: name.trim(),
            email: email.trim(),
            role: role,
            photoUrl: defaultPhoto,
            bio: 'New EduSphere ${role.name}. Ready to expand knowledge.',
            xp: role == UserRole.instructor ? 1000 : 250,
            streak: 1,
            badges: ['New Joiner'],
          );

          await _firestore!.collection('users').doc(credential.user!.uid).set(_localUser!.toJson());
          await credential.user!.updateDisplayName(name.trim());
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
    final defaultPhoto = role == UserRole.instructor
        ? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';

    _localUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      role: role,
      photoUrl: defaultPhoto,
      bio: 'New EduSphere ${role.name}.',
      xp: role == UserRole.instructor ? 1000 : 250,
      streak: 1,
      badges: ['New Joiner'],
    );
    debugPrint('[AuthService] Local user registered: ${_localUser?.email} (${_localUser?.role.name})');
    return _localUser;
  }

  /// Sign In with Google
  Future<UserModel?> signInWithGoogle({UserRole role = UserRole.student}) async {
    if (FirebaseService.isInitialized && kIsWeb && _firebaseAuth != null && _firestore != null) {
      try {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCredential = await _firebaseAuth!.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          final userDoc = await _firestore!.collection('users').doc(userCredential.user!.uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            _localUser = UserModel.fromJson(userDoc.data()!);
          } else {
            _localUser = UserModel(
              id: userCredential.user!.uid,
              name: userCredential.user!.displayName ?? 'Google User',
              email: userCredential.user!.email ?? 'user@gmail.com',
              role: role,
              photoUrl: userCredential.user!.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
              bio: 'Signed in with Google.',
              xp: 500,
              streak: 1,
              badges: ['Google Verified'],
            );
            await _firestore!.collection('users').doc(userCredential.user!.uid).set(_localUser!.toJson());
          }
          return _localUser;
        }
      } catch (e) {
        debugPrint('[AuthService] Google Sign-in error: $e');
      }
    }

    // Fallback simulated Google sign-in
    _localUser = UserModel(
      id: 'google_user_01',
      name: 'Google Learner',
      email: 'learner@gmail.com',
      role: role,
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      bio: 'Learner via Google account.',
      xp: 750,
      streak: 2,
      badges: ['Google Sign-In', 'Verified Learner'],
    );
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

    if (FirebaseService.isInitialized && _firestore != null) {
      try {
        final updateData = <String, dynamic>{};
        if (name != null) updateData['name'] = name;
        if (bio != null) updateData['bio'] = bio;
        if (photoUrl != null) updateData['photoUrl'] = photoUrl;
        await _firestore!.collection('users').doc(_localUser!.id).update(updateData);
        if (_firebaseAuth?.currentUser != null) {
          if (name != null) await _firebaseAuth!.currentUser!.updateDisplayName(name);
          if (photoUrl != null) await _firebaseAuth!.currentUser!.updatePhotoURL(photoUrl);
        }
        debugPrint('[AuthService] Profile updated in Firestore for ${_localUser!.email}');
      } catch (e) {
        debugPrint('[AuthService] Firestore profile update note: $e');
      }
    }

    debugPrint('[AuthService] Profile updated: name=${_localUser!.name}, bio=${_localUser!.bio}');
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
        await _firestore!.collection('users').doc(_localUser!.id).update({'xp': newXp});
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
        await _firestore!.collection('users').doc(_localUser!.id).update({'badges': updatedBadges});
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
        await _firestore!.collection('users').doc(_localUser!.id).update({'streak': streak});
      } catch (_) {}
    }
    return _localUser;
  }

  /// Role Switcher (for development & demo testing)
  void switchRole(UserRole newRole) {
    if (_localUser != null) {
      _localUser = _localUser!.copyWith(role: newRole);
      if (FirebaseService.isInitialized && _firestore != null) {
        _firestore!.collection('users').doc(_localUser!.id).update({'role': newRole.name}).catchError((_) {});
      }
      debugPrint('[AuthService] Switched role to: ${newRole.name}');
    }
  }
}
