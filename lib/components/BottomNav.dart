import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../utils/auth_gate.dart';

class CustomBottomNav extends ConsumerWidget {
  final String currentLocation;

  const CustomBottomNav({
    super.key,
    required this.currentLocation,
  });

  int _calculateStudentIndex() {
    if (currentLocation.startsWith('/home')) return 0;
    if (currentLocation.startsWith('/courses')) return 1;
    if (currentLocation.startsWith('/my-learning')) return 2;
    if (currentLocation.startsWith('/wishlist')) return 3;
    if (currentLocation.startsWith('/profile')) return 4;
    return 0;
  }

  int _calculateInstructorIndex() {
    if (currentLocation.startsWith('/instructor')) return 0;
    if (currentLocation.startsWith('/builder')) return 1;
    if (currentLocation.startsWith('/earnings')) return 2;
    if (currentLocation.startsWith('/profile')) return 3;
    return 0;
  }

  void _onStudentTapped(int index, BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/courses');
        break;
      case 2:
        AuthGateHelper.requireAuth(
          context,
          ref,
          actionTitle: 'Access My Learning',
          reason: 'Sign in to view your enrolled courses, resume video lessons, and track completion progress.',
          onAuthenticated: () {
            if (context.mounted) context.go('/my-learning');
          },
        );
        break;
      case 3:
        context.go('/wishlist');
        break;
      case 4:
        AuthGateHelper.requireAuth(
          context,
          ref,
          actionTitle: 'View Your Profile',
          reason: 'Sign in to view your learning streak, global leaderboard position, and certificates.',
          onAuthenticated: () {
            if (context.mounted) context.go('/profile');
          },
        );
        break;
    }
  }

  void _onInstructorTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/instructor');
        break;
      case 1:
        context.go('/builder');
        break;
      case 2:
        context.go('/earnings');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isInstructor = user?.role == UserRole.instructor;

    if (isInstructor) {
      final selectedIndex = _calculateInstructorIndex();
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.surfaceContainerHigh, width: 1),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              final isSelected = states.contains(MaterialState.selected);
              return AppTypography.labelSmall.copyWith(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.secondary : AppColors.outline,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _onInstructorTapped(index, context),
            backgroundColor: Colors.white,
            indicatorColor: AppColors.secondaryFixedDim.withOpacity(0.35),
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: AppColors.secondary),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle, color: AppColors.secondary),
                label: 'Builder',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.secondary),
                label: 'Earnings',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.secondary),
                label: 'Profile',
              ),
            ],
          ),
        ),
      );
    }

    final selectedIndex = _calculateStudentIndex();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerHigh, width: 1),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final isSelected = states.contains(MaterialState.selected);
            return AppTypography.labelSmall.copyWith(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.secondary : AppColors.outline,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onStudentTapped(index, context, ref),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.secondaryFixedDim.withOpacity(0.35),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.secondary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore, color: AppColors.secondary),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school, color: AppColors.secondary),
              label: 'Learning',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite, color: AppColors.secondary),
              label: 'Wishlist',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.secondary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
