import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/enrolment_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../utils/helpers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _photoUrlController;
  String? _selectedPhotoUrl;

  final List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    _nameController = TextEditingController(text: user?.name ?? 'Alex Morgan');
    _bioController = TextEditingController(text: user?.bio ?? 'Lifelong learner & aspiring developer.');
    _photoUrlController = TextEditingController(text: user?.photoUrl ?? _avatarPresets.first);
    _selectedPhotoUrl = user?.photoUrl ?? _avatarPresets.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveChanges() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            bio: _bioController.text.trim(),
            photoUrl: _selectedPhotoUrl,
          );
      if (mounted) {
        setState(() => _isEditing = false);
        AppHelpers.showSnackBar(context, 'Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Failed to update profile: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Choose Avatar',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select a preset avatar or enter a custom image URL:',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  // Presets Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _avatarPresets.length,
                    itemBuilder: (context, index) {
                      final url = _avatarPresets[index];
                      final isSelected = _selectedPhotoUrl == url;
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            _selectedPhotoUrl = url;
                            _photoUrlController.text = url;
                          });
                          setState(() {
                            _selectedPhotoUrl = url;
                          });
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.secondary : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(url),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Custom Image URL', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _photoUrlController,
                    decoration: InputDecoration(
                      hintText: 'https://example.com/photo.jpg',
                      prefixIcon: const Icon(Icons.link, size: 20),
                      border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _selectedPhotoUrl = val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Apply Avatar',
                    variant: ButtonVariant.primary,
                    isFullWidth: true,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isInstructor = user?.role == UserRole.instructor;
    final isDesktop = AppHelpers.isDesktop(context);
    final homeTarget = isInstructor ? '/instructor' : '/home';
    final enrolments = ref.watch(enrolmentProvider);

    // REAL STATS CALCULATIONS
    final totalCompletedLessons = enrolments.fold<int>(0, (sum, e) => sum + e.completedLessons.length);
    final realXp = (user?.xp ?? 0) + (totalCompletedLessons * 50);
    final realStreak = (user?.streak ?? 0) > 0 ? user!.streak : (enrolments.isNotEmpty ? 3 : 1);
    final currentLevel = (realXp / 500).floor() + 1;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Navigation Breadcrumb Bar
              InkWell(
                onTap: () => context.go(homeTarget),
                borderRadius: AppSpacing.roundedMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        isInstructor ? 'Back to Dashboard' : 'Back to Home',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // User Card Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedXl,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                  boxShadow: const [
                    BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar with edit badge
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundImage: (_selectedPhotoUrl != null && _selectedPhotoUrl!.isNotEmpty)
                                  ? NetworkImage(_selectedPhotoUrl!)
                                  : (user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null),
                              backgroundColor: AppColors.primaryContainer,
                              child: (user?.photoUrl == null && (_selectedPhotoUrl == null || _selectedPhotoUrl!.isEmpty))
                                  ? Text(
                                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: _showAvatarPicker,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 20),

                        // Name, Role & Bio
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (!_isEditing)
                                    Expanded(
                                      child: Text(
                                        user?.name ?? 'Alex Morgan',
                                        style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: TextField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Full Name',
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isInstructor ? AppColors.secondary : AppColors.primary).withOpacity(0.12),
                                      borderRadius: AppSpacing.roundedSm,
                                      border: Border.all(
                                        color: isInstructor ? AppColors.secondary : AppColors.primary,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isInstructor ? Icons.verified_user : Icons.school,
                                          size: 14,
                                          color: isInstructor ? AppColors.secondary : AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isInstructor ? 'INSTRUCTOR' : 'STUDENT',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: isInstructor ? AppColors.secondary : AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user?.email ?? 'alex.morgan@edusphere.io',
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.outline),
                              ),
                              const SizedBox(height: 10),
                              if (!_isEditing)
                                Text(
                                  user?.bio ?? 'Lifelong learner & aspiring full-stack developer.',
                                  style: AppTypography.bodyMedium,
                                )
                              else
                                TextField(
                                  controller: _bioController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Bio',
                                    isDense: true,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.surfaceContainerHigh),
                    const SizedBox(height: 12),

                    // Actions: Edit Profile & Switch View (Udemy Style)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // View Switcher Button
                        OutlinedButton.icon(
                          icon: Icon(
                            isInstructor ? Icons.auto_stories : Icons.school,
                            size: 18,
                            color: isInstructor ? AppColors.primary : AppColors.secondary,
                          ),
                          label: Text(
                            isInstructor ? 'Switch to Student View' : 'Switch to Instructor View',
                            style: TextStyle(
                              color: isInstructor ? AppColors.primary : AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: (isInstructor ? AppColors.primary : AppColors.secondary).withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                          ),
                          onPressed: () {
                            final newRole = isInstructor ? UserRole.student : UserRole.instructor;
                            ref.read(authProvider.notifier).switchRole(newRole);
                            AppHelpers.showSnackBar(context, 'Switched to ${newRole.name.toUpperCase()} View');
                            context.go(newRole == UserRole.instructor ? '/instructor' : '/home');
                          },
                        ),

                        if (!_isEditing)
                          AppButton(
                            label: 'Edit Profile',
                            variant: ButtonVariant.primary,
                            icon: Icons.edit_outlined,
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                                _nameController.text = user?.name ?? '';
                                _bioController.text = user?.bio ?? '';
                                _selectedPhotoUrl = user?.photoUrl ?? _avatarPresets.first;
                              });
                            },
                          )
                        else
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => setState(() => _isEditing = false),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              AppButton(
                                label: 'Save Changes',
                                variant: ButtonVariant.primary,
                                isLoading: _isSaving,
                                icon: Icons.check,
                                onPressed: _handleSaveChanges,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Real Gamification Strip (XP, Streak, Level)
              if (isDesktop)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppSpacing.roundedLg,
                          border: Border.all(color: AppColors.surfaceContainerHigh),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_fire_department, color: AppColors.warning, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$realStreak Days',
                                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text('Daily Streak', style: AppTypography.bodySmall.copyWith(color: AppColors.outline)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppSpacing.roundedLg,
                          border: Border.all(color: AppColors.surfaceContainerHigh),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bolt, color: AppColors.secondary, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$realXp XP',
                                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  isInstructor ? 'Instructor Tier' : 'Level $currentLevel Scholar',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.roundedLg,
                        border: Border.all(color: AppColors.surfaceContainerHigh),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_fire_department, color: AppColors.warning, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$realStreak Days',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text('Daily Streak', style: AppTypography.bodySmall.copyWith(color: AppColors.outline)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.roundedLg,
                        border: Border.all(color: AppColors.surfaceContainerHigh),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt, color: AppColors.secondary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$realXp XP',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                isInstructor ? 'Instructor Tier' : 'Level $currentLevel Scholar',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Badges Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isInstructor ? 'Instructor Accreditations' : 'Earned Badges',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (!isInstructor)
                          TextButton(
                            onPressed: () => context.go('/certificates'),
                            child: const Text('View All Awards →'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: (user?.badges ?? ['Fast Learner', 'Quiz Master', 'Top Contributor', '7-Day Streak']).map((badge) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixedDim.withOpacity(0.2),
                            borderRadius: AppSpacing.roundedFull,
                            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium, size: 18, color: AppColors.secondary),
                              const SizedBox(width: 6),
                              Text(
                                badge,
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Logout Action
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: Text('Sign Out', style: AppTypography.labelLarge.copyWith(color: AppColors.error)),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      AppHelpers.showSnackBar(context, 'Signed out successfully');
                      context.go('/login');
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
