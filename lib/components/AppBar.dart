import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../utils/helpers.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isInstructor = user?.role == UserRole.instructor;
    final cartItems = ref.watch(cartProvider);
    final isDesktop = AppHelpers.isDesktop(context);
    final homeTarget = isInstructor ? '/instructor' : '/home';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHigh, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
          ),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                  tooltip: 'Go Back',
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(homeTarget);
                    }
                  },
                )
              else
                // Logo & Brand
                InkWell(
                  onTap: () => context.go(homeTarget),
                  borderRadius: AppSpacing.roundedMd,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isInstructor ? AppColors.secondary : AppColors.primary,
                          borderRadius: AppSpacing.roundedMd,
                        ),
                        child: Icon(
                          isInstructor ? Icons.dashboard_customize : Icons.auto_stories,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isInstructor ? 'EduSphere Instructor' : 'EduSphere',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),

              // Desktop Role-Specific Navigation Links
              if (isDesktop) ...[
                const SizedBox(width: 32),
                if (!isInstructor) ...[
                  // Student Navigation
                  const _NavLink(label: 'Home', path: '/home'),
                  const SizedBox(width: 16),
                  const _NavLink(label: 'Explore Courses', path: '/courses'),
                  const SizedBox(width: 16),
                  const _NavLink(label: 'My Learning', path: '/my-learning'),
                  const SizedBox(width: 16),
                  const _NavLink(label: 'Certificates', path: '/certificates'),
                ] else ...[
                  // Instructor Navigation (Marketplace removed from instructor tabs)
                  const _NavLink(label: 'Dashboard', path: '/instructor'),
                  const SizedBox(width: 16),
                  const _NavLink(label: 'Course Builder', path: '/builder'),
                  const SizedBox(width: 16),
                  const _NavLink(label: 'Earnings & Payouts', path: '/earnings'),
                ],
              ],

              const Spacer(),

              // Actions
              if (actions != null)
                ...actions!
              else ...[
                // Udemy-Style "Switch to Instructor / Switch to Student" Quick Button
                if (user != null)
                  if (!isInstructor)
                    // In Student Mode -> Offer Switch to Instructor View
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton.icon(
                        icon: const Icon(Icons.school, size: 18),
                        label: Text(isDesktop ? 'Instructor View' : 'Teach'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          textStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          ref.read(authProvider.notifier).switchRole(UserRole.instructor);
                          AppHelpers.showSnackBar(context, 'Switched to Instructor View');
                          context.go('/instructor');
                        },
                      ),
                    )
                  else
                    // In Instructor Mode -> Offer Switch to Student View
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton.icon(
                        icon: const Icon(Icons.auto_stories, size: 18),
                        label: Text(isDesktop ? 'Student View' : 'Learn'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          ref.read(authProvider.notifier).switchRole(UserRole.student);
                          AppHelpers.showSnackBar(context, 'Switched to Student View');
                          context.go('/home');
                        },
                      ),
                    ),

                if (!isInstructor) ...[
                  // Cart Icon with Badge (Students only)
                  IconButton(
                    icon: Badge(
                      label: Text('${cartItems.length}'),
                      isLabelVisible: cartItems.isNotEmpty,
                      backgroundColor: AppColors.secondary,
                      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.onSurface),
                    ),
                    onPressed: () => context.go('/cart'),
                    tooltip: 'Shopping Cart',
                  ),

                  // Wishlist Icon (Students only)
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: AppColors.onSurface),
                    onPressed: () => context.go('/wishlist'),
                    tooltip: 'Wishlist',
                  ),
                  const SizedBox(width: 4),
                ] else ...[
                  // Instructor "+ New Course" Action
                  if (isDesktop)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create Course'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                        ),
                        onPressed: () => context.go('/builder'),
                      ),
                    ),
                ],

                // User Profile Dropdown
                if (user != null)
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'profile') {
                        context.go('/profile');
                      } else if (val == 'switch_view') {
                        final newRole = isInstructor ? UserRole.student : UserRole.instructor;
                        ref.read(authProvider.notifier).switchRole(newRole);
                        AppHelpers.showSnackBar(context, 'Switched to ${newRole.name.toUpperCase()} View');
                        context.go(newRole == UserRole.instructor ? '/instructor' : '/home');
                      } else if (val == 'logout') {
                        ref.read(authProvider.notifier).signOut();
                        context.go('/login');
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 18),
                            const SizedBox(width: 8),
                            Text('${user.name} (${user.role.name.toUpperCase()})'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'switch_view',
                        child: Row(
                          children: [
                            Icon(
                              isInstructor ? Icons.auto_stories : Icons.school,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isInstructor ? 'Switch to Student View' : 'Switch to Instructor View',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Log Out', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      backgroundColor: isInstructor ? AppColors.secondary : AppColors.primaryContainer,
                      child: user.photoUrl == null
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign In'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final String path;

  const _NavLink({required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    final isCurrent = GoRouterState.of(context).matchedLocation == path;

    return TextButton(
      onPressed: () => context.go(path),
      style: TextButton.styleFrom(
        foregroundColor: isCurrent ? AppColors.secondary : AppColors.onSurfaceVariant,
        textStyle: AppTypography.labelLarge.copyWith(
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }
}
