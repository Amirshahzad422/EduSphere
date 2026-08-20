import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/AppBar.dart';
import '../components/BottomNav.dart';
import '../styles/colors.dart';
import '../utils/helpers.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppHelpers.isDesktop(context);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    // Check if back button should be shown for sub-detail pages
    final isRootScreen = currentLocation == '/home' ||
        currentLocation == '/courses' ||
        currentLocation == '/my-learning' ||
        currentLocation == '/wishlist' ||
        currentLocation == '/profile' ||
        currentLocation == '/instructor';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        showBackButton: !isRootScreen,
      ),
      body: child,
      bottomNavigationBar: !isDesktop
          ? CustomBottomNav(currentLocation: currentLocation)
          : null,
    );
  }
}
