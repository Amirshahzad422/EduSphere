import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/AuthGateModal.dart';
import '../providers/auth_provider.dart';

class AuthGateHelper {
  AuthGateHelper._();

  /// Executes [onAuthenticated] immediately if the user is signed in.
  /// If the user is a guest, presents the [AuthGateModal] and automatically
  /// executes [onAuthenticated] upon successful sign-in or social login.
  static Future<void> requireAuth(
    BuildContext context,
    WidgetRef ref, {
    required String actionTitle,
    String? reason,
    required VoidCallback onAuthenticated,
  }) async {
    final user = ref.read(authProvider);
    if (user != null) {
      onAuthenticated();
      return;
    }

    await AuthGateModal.show(
      context,
      actionTitle: actionTitle,
      reason: reason,
      onAuthenticated: onAuthenticated,
    );
  }
}
