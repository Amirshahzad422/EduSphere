import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(_authService.currentUser);

  bool get isAuthenticated => state != null;
  bool get isStudent => state?.role == UserRole.student;
  bool get isInstructor => state?.role == UserRole.instructor;
  UserRole? get role => state?.role;

  Future<UserModel?> signIn(String email, String password) async {
    final user = await _authService.signInWithEmail(email, password);
    state = user;
    return user;
  }

  Future<UserModel?> register(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.student,
  }) async {
    final user = await _authService.registerWithEmail(name, email, password, role: role);
    state = user;
    return user;
  }

  Future<UserModel?> signInWithGoogle({UserRole role = UserRole.student}) async {
    final user = await _authService.signInWithGoogle(role: role);
    state = user;
    return user;
  }

  Future<void> updateProfile({String? name, String? bio, String? photoUrl}) async {
    final updated = await _authService.updateProfile(name: name, bio: bio, photoUrl: photoUrl);
    if (updated != null) {
      state = updated;
    }
  }

  Future<void> addXp(int points) async {
    final updated = await _authService.addXp(points);
    if (updated != null) {
      state = updated;
    }
  }

  Future<void> awardBadge(String badge) async {
    final updated = await _authService.awardBadge(badge);
    if (updated != null) {
      state = updated;
    }
  }

  Future<void> updateStreak(int streak) async {
    final updated = await _authService.updateStreak(streak);
    if (updated != null) {
      state = updated;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }

  void switchRole(UserRole newRole) {
    _authService.switchRole(newRole);
    if (state != null) {
      state = state!.copyWith(role: newRole);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider)?.role;
});
