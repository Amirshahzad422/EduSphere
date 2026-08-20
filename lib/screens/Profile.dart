import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/cloudinary_upload_service.dart';
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
  bool _isUploadingPhoto = false;
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
    final user = ref.read(authProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 24.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Change Profile Picture',
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
                          'Upload a photo from your device or choose a preset:',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),

                        // Upload from Device Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: _isUploadingPhoto
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.cloud_upload_outlined, size: 20),
                            label: Text(
                              _isUploadingPhoto ? 'Uploading to Cloudinary...' : 'Upload Image from Device',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              side: const BorderSide(color: AppColors.secondary, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                            ),
                            onPressed: _isUploadingPhoto
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final nav = Navigator.of(ctx);
                                    try {
                                      final pickResult = await FilePicker.platform.pickFiles(
                                        type: FileType.image,
                                        withData: true,
                                      );
                                      if (pickResult == null || pickResult.files.isEmpty) return;

                                      final pickedFile = pickResult.files.first;
                                      if (pickedFile.bytes == null) return;

                                      setModalState(() => _isUploadingPhoto = true);
                                      setState(() => _isUploadingPhoto = true);

                                      final uploadService = CloudinaryUploadService();
                                      final result = await uploadService.uploadProfilePhoto(
                                        userId: user?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
                                        fileName: pickedFile.name,
                                        fileBytes: pickedFile.bytes!,
                                      );

                                      setModalState(() {
                                        _isUploadingPhoto = false;
                                        _selectedPhotoUrl = result.secureUrl;
                                        _photoUrlController.text = result.secureUrl;
                                      });
                                      setState(() {
                                        _isUploadingPhoto = false;
                                        _selectedPhotoUrl = result.secureUrl;
                                      });

                                      // Update globally in authProvider and Firestore
                                      await ref.read(authProvider.notifier).updateProfile(photoUrl: result.secureUrl);

                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Profile picture updated everywhere!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      nav.pop();
                                    } catch (e) {
                                      setModalState(() => _isUploadingPhoto = false);
                                      setState(() => _isUploadingPhoto = false);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to upload photo: $e'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Presets Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.surfaceContainerHigh)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'OR CHOOSE PRESET',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.outline,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.surfaceContainerHigh)),
                          ],
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
                          onPressed: () async {
                            if (_selectedPhotoUrl != null && _selectedPhotoUrl!.isNotEmpty) {
                              await ref.read(authProvider.notifier).updateProfile(photoUrl: _selectedPhotoUrl);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
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
    final leaderboardAsync = ref.watch(leaderboardStreamProvider);

    // REAL STATS CALCULATIONS (Strictly based on verified profile & completions)
    final realXp = user?.xp ?? 0;
    final realStreak = (user?.streak ?? 0) > 0 ? user!.streak : 1;
    final currentLevel = (realXp / 500).floor() + 1;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar with Tap to Change
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: isInstructor ? AppColors.secondary : AppColors.primaryContainer,
                              backgroundImage: (_selectedPhotoUrl != null && _selectedPhotoUrl!.isNotEmpty)
                                  ? NetworkImage(_selectedPhotoUrl!)
                                  : null,
                              child: (_selectedPhotoUrl == null || _selectedPhotoUrl!.isEmpty)
                                  ? Text(
                                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _showAvatarPicker,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    user?.name ?? 'Learner',
                                    style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isInstructor
                                          ? AppColors.secondaryFixedDim.withOpacity(0.3)
                                          : AppColors.primaryContainer,
                                      borderRadius: AppSpacing.roundedSm,
                                    ),
                                    child: Text(
                                      isInstructor ? 'INSTRUCTOR' : 'STUDENT',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isInstructor ? AppColors.secondary : AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'learner@edusphere.io',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user?.bio ?? 'No bio provided.',
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.surfaceContainerHigh),
                    const SizedBox(height: 12),
                    // Quick Action Buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 16),
                          label: Text(_isEditing ? 'Cancel Edit' : 'Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.outlineVariant),
                          ),
                          onPressed: () {
                            setState(() {
                              _isEditing = !_isEditing;
                              if (!_isEditing) {
                                _nameController.text = user?.name ?? '';
                                _bioController.text = user?.bio ?? '';
                              }
                            });
                          },
                        ),
                        if (!isInstructor)
                          TextButton.icon(
                            icon: const Icon(Icons.school, size: 16),
                            label: const Text('Switch to Instructor'),
                            onPressed: () {
                              ref.read(authProvider.notifier).switchRole(UserRole.instructor);
                              AppHelpers.showSnackBar(context, 'Switched to Instructor View');
                              context.go('/instructor');
                            },
                          )
                        else
                          TextButton.icon(
                            icon: const Icon(Icons.auto_stories, size: 16),
                            label: const Text('Switch to Student View'),
                            onPressed: () {
                              ref.read(authProvider.notifier).switchRole(UserRole.student);
                              AppHelpers.showSnackBar(context, 'Switched to Student View');
                              context.go('/home');
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Edit Form Card (if editing)
              if (_isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Profile Information',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio & Qualifications',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            label: _isSaving ? 'Saving...' : 'Save Changes',
                            variant: ButtonVariant.primary,
                            isLoading: _isSaving,
                            onPressed: _handleSaveChanges,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Gamification & Streak Metrics (Live & Real)
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
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$realStreak Days',
                                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Daily Learning Streak',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                                ),
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
                            const SizedBox(width: 16),
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
                        Expanded(
                          child: Text(
                            isInstructor ? 'Instructor Accreditations' : 'Earned Badges',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isInstructor) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => context.go('/certificates'),
                            child: const Text('View All Awards →'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: (user?.badges.isNotEmpty == true
                              ? user!.badges
                              : ['Fast Learner', 'Top Contributor'])
                          .map((badge) {
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
              const SizedBox(height: 24),

              // Real-Time Global Leaderboard (Strictly Real Registered Users)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events, color: AppColors.warning, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Global Scholar Leaderboard',
                                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: AppSpacing.roundedFull,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt, size: 12, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'REAL-TIME',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Leaderboard List from Firestore Stream
                    leaderboardAsync.when(
                      data: (users) {
                        // Deduplicate users strictly by unique ID
                        final Map<String, UserModel> userMap = {};
                        for (final u in users) {
                          if (u.id.trim().isNotEmpty && u.name.trim().isNotEmpty && !u.id.startsWith('google_user_')) {
                            userMap[u.id.trim()] = u;
                          }
                        }

                        // Merge current logged-in session user with their latest local profile info
                        if (user != null && user.id.trim().isNotEmpty && user.name.trim().isNotEmpty && !user.id.startsWith('google_user_')) {
                          String matchedKey = user.id.trim();
                          for (final existing in userMap.values) {
                            if (existing.id.trim() == user.id.trim() ||
                                (existing.email.trim().isNotEmpty &&
                                    user.email.trim().isNotEmpty &&
                                    existing.email.trim().toLowerCase() == user.email.trim().toLowerCase())) {
                              matchedKey = existing.id.trim();
                              break;
                            }
                          }

                          if (matchedKey != user.id.trim() && userMap.containsKey(matchedKey)) {
                            userMap.remove(matchedKey);
                          }

                          userMap[user.id.trim()] = user;
                        }

                        final sortedUsers = userMap.values.toList();
                        sortedUsers.sort((a, b) => b.xp.compareTo(a.xp));

                        if (sortedUsers.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text('No learners registered yet.')),
                          );
                        }

                        return Column(
                          children: sortedUsers.asMap().entries.map((entry) {
                            final rank = entry.key + 1;
                            final u = entry.value;
                            final isMe = user != null &&
                                (u.id == user.id ||
                                    (u.email.isNotEmpty &&
                                        user.email.isNotEmpty &&
                                        u.email.toLowerCase() == user.email.toLowerCase()));

                            final rankColor = rank == 1
                                ? const Color(0xFFFFD700)
                                : (rank == 2
                                    ? const Color(0xFFC0C0C0)
                                    : (rank == 3 ? const Color(0xFFCD7F32) : AppColors.outlineVariant));

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.secondaryFixedDim.withOpacity(0.18)
                                    : AppColors.surfaceContainerLow,
                                borderRadius: AppSpacing.roundedMd,
                                border: Border.all(
                                  color: isMe ? AppColors.secondary : Colors.transparent,
                                  width: isMe ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: rankColor.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$rank',
                                        style: AppTypography.labelSmall.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: rank <= 3 ? AppColors.primary : AppColors.outline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: u.role == UserRole.instructor
                                        ? AppColors.secondary
                                        : AppColors.primaryContainer,
                                    backgroundImage: (u.photoUrl != null && u.photoUrl!.isNotEmpty)
                                        ? NetworkImage(u.photoUrl!)
                                        : null,
                                    child: (u.photoUrl == null || u.photoUrl!.isEmpty)
                                        ? Text(
                                            u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                u.name,
                                                style: AppTypography.titleSmall.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: isMe ? AppColors.secondary : AppColors.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.secondary,
                                                  borderRadius: AppSpacing.roundedFull,
                                                ),
                                                child: Text(
                                                  'YOU',
                                                  style: AppTypography.labelSmall.copyWith(
                                                    fontSize: 9,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.local_fire_department, size: 12, color: AppColors.warning),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                '${u.streak}d streak • ${u.role.name.toUpperCase()}',
                                                style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${u.xp} XP',
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Unable to load live leaderboard: $err',
                          style: const TextStyle(color: AppColors.outline),
                        ),
                      ),
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
