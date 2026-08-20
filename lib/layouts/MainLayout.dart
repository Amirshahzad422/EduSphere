import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../components/AppBar.dart';
import '../components/BottomNav.dart';
import '../models/live_class_model.dart';
import '../providers/live_class_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../utils/helpers.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = AppHelpers.isDesktop(context);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final activeLiveSession = ref.watch(activeUserLiveSessionProvider);

    // Check if back button should be shown for sub-detail pages
    final isRootScreen = currentLocation == '/home' ||
        currentLocation == '/courses' ||
        currentLocation == '/my-learning' ||
        currentLocation == '/wishlist' ||
        currentLocation == '/profile' ||
        currentLocation == '/instructor';

    final isAlreadyInLiveRoom = currentLocation.startsWith('/live-class');
    final showFloatingLivePill = activeLiveSession != null && !isAlreadyInLiveRoom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        showBackButton: !isRootScreen,
      ),
      body: Stack(
        children: [
          child,
          // Global Persistent Floating Live Class Mini-Pill / PiP Banner
          if (showFloatingLivePill)
            Positioned(
              bottom: isDesktop ? 24 : 16,
              right: isDesktop ? 24 : 16,
              left: isDesktop ? null : 16,
              child: _buildFloatingLivePill(context, activeLiveSession),
            ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? CustomBottomNav(currentLocation: currentLocation)
          : null,
    );
  }

  Widget _buildFloatingLivePill(BuildContext context, LiveClassModel liveClass) {
    return Material(
      elevation: 8,
      borderRadius: AppSpacing.roundedFull,
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/live-class/${liveClass.id}'),
        borderRadius: AppSpacing.roundedFull,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: AppSpacing.roundedFull,
            border: Border.all(color: AppColors.error, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.35),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing Red Live Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Title metadata
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liveClass.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Class in progress • Tap to return',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondaryFixedDim,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Action Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
