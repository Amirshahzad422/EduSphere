import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../utils/helpers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _agreeTerms = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() != true) return;
    if (!_agreeTerms) {
      AppHelpers.showSnackBar(context, 'Please agree to the Terms of Service', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authProvider.notifier).register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
            role: _selectedRole,
          );

      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Account created successfully as ${_selectedRole.name.toUpperCase()}!',
        );

        // Role-based routing: Instructors route to Instructor Dashboard, Students route to Home
        if (user?.role == UserRole.instructor) {
          context.go('/instructor');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Registration failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isGoogleLoading = true);
    try {
      final user = await ref.read(authProvider.notifier).signInWithGoogle(role: _selectedRole);
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Account created via Google as ${_selectedRole.name.toUpperCase()}!',
        );
        if (user?.role == UserRole.instructor) {
          context.go('/instructor');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Google Sign-up failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppHelpers.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1080 : 480),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Hero Banner (Desktop Only matching /stitch/edusphere_register/)
                  if (isDesktop)
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 64.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: AppSpacing.roundedMd,
                              ),
                              child: const Icon(Icons.auto_stories, size: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Join EduSphere',
                              style: AppTypography.displayLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Begin your journey towards career progression and deep knowledge. A structured, architectural learning experience awaits.',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.onSurfaceVariant,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 32),
                            ClipRRect(
                              borderRadius: AppSpacing.roundedXl,
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: Image.network(
                                  'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.surfaceContainerHigh,
                                    child: const Center(
                                      child: Icon(Icons.school, size: 64, color: AppColors.outline),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Right Registration Card
                  Expanded(
                    flex: isDesktop ? 5 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: AppSpacing.roundedXl,
                        border: Border.all(color: AppColors.surfaceContainerHigh),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!isDesktop) ...[
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: AppSpacing.roundedMd,
                                  ),
                                  child: const Icon(Icons.auto_stories, size: 24, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              'Create Account',
                              style: AppTypography.headlineLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                              textAlign: isDesktop ? TextAlign.start : TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                                ),
                                InkWell(
                                  onTap: () => context.go('/login'),
                                  child: Text(
                                    'Log in',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Role Selection Cards (Student vs Instructor)
                            Text(
                              'I am joining as a:',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // Student Card
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedRole = UserRole.student),
                                    borderRadius: AppSpacing.roundedMd,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedRole == UserRole.student
                                            ? AppColors.secondaryFixedDim.withOpacity(0.18)
                                            : AppColors.surfaceContainerLowest,
                                        borderRadius: AppSpacing.roundedMd,
                                        border: Border.all(
                                          color: _selectedRole == UserRole.student
                                              ? AppColors.secondary
                                              : AppColors.outlineVariant,
                                          width: _selectedRole == UserRole.student ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.school,
                                            size: 20,
                                            color: _selectedRole == UserRole.student
                                                ? AppColors.secondary
                                                : AppColors.outline,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Student',
                                            style: AppTypography.labelLarge.copyWith(
                                              color: _selectedRole == UserRole.student
                                                  ? AppColors.secondary
                                                  : AppColors.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Instructor Card
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedRole = UserRole.instructor),
                                    borderRadius: AppSpacing.roundedMd,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedRole == UserRole.instructor
                                            ? AppColors.secondaryFixedDim.withOpacity(0.18)
                                            : AppColors.surfaceContainerLowest,
                                        borderRadius: AppSpacing.roundedMd,
                                        border: Border.all(
                                          color: _selectedRole == UserRole.instructor
                                              ? AppColors.secondary
                                              : AppColors.outlineVariant,
                                          width: _selectedRole == UserRole.instructor ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.co_present,
                                            size: 20,
                                            color: _selectedRole == UserRole.instructor
                                                ? AppColors.secondary
                                                : AppColors.outline,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Instructor',
                                            style: AppTypography.labelLarge.copyWith(
                                              color: _selectedRole == UserRole.instructor
                                                  ? AppColors.secondary
                                                  : AppColors.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Full Name Field
                            Text(
                              'Full Name',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'Alex Morgan',
                                prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.outline),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLowest,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedMd,
                                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedMd,
                                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedMd,
                                  borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            Text(
                              'Email Address',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'name@example.com',
                                prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.outline),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLowest,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedMd,
                                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedMd,
                                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedMd,
                                  borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            Text(
                              'Password',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Minimum 6 characters',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: AppColors.outline,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLowest,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedMd,
                                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedMd,
                                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedMd,
                                  borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Terms Agreement Checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agreeTerms,
                                    activeColor: AppColors.secondary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) => setState(() => _agreeTerms = val ?? true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'I agree to the Terms of Service and Privacy Policy',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Create Account Button
                            AppButton(
                              label: 'Create Account',
                              variant: ButtonVariant.primary,
                              isLoading: _isLoading,
                              isFullWidth: true,
                              onPressed: _handleRegister,
                            ),
                            const SizedBox(height: 16),

                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider(color: AppColors.outlineVariant)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(
                                    'OR',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.outline,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: AppColors.outlineVariant)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Google Sign-Up Button
                            OutlinedButton(
                              onPressed: _isGoogleLoading ? null : _handleGoogleSignUp,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.outlineVariant),
                                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                                backgroundColor: Colors.white,
                              ),
                              child: _isGoogleLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(shape: BoxShape.circle),
                                          child: const Center(
                                            child: Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sign Up with Google',
                                          style: AppTypography.labelLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
