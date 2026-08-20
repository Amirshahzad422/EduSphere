import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../utils/helpers.dart';

// Note: No Stitch reference found for Contact screen — used consistent styling matching lib/styles/
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Technical Support';
  bool _isSending = false;

  final List<String> _categories = [
    'Technical Support',
    'Course Inquiry',
    'Enterprise Training',
    'Instructor Partnership',
    'Billing & Payout',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isSending = false);
        AppHelpers.showSnackBar(
          context,
          '✅ Thank you ${_nameController.text.trim()}! Your message regarding "$_selectedCategory" has been received.',
        );
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppHelpers.isDesktop(context);

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
              // Back Navigation Breadcrumb
              InkWell(
                onTap: () => context.go('/home'),
                borderRadius: AppSpacing.roundedMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Home',
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

              Text(
                'Contact Support & Inquiries',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Have questions about course access, certificates, or enterprise training? We are here to help.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 28),

              // Contact Form & Info Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 750;

                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Column
                      Expanded(
                        flex: isWide ? 6 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.roundedLg,
                            border: Border.all(color: AppColors.surfaceContainerHigh),
                            boxShadow: const [
                              BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Send a Message', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: const InputDecoration(labelText: 'Inquiry Subject'),
                                  items: _categories.map((c) {
                                    return DropdownMenuItem(value: c, child: Text(c));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCategory = val);
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(labelText: 'Your Name *'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(labelText: 'Email Address *'),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                                    if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email address';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _messageController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(labelText: 'How can we help? *'),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your message' : null,
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: AppButton(
                                    label: 'Send Message',
                                    variant: ButtonVariant.primary,
                                    icon: Icons.send,
                                    isLoading: _isSending,
                                    onPressed: _handleSubmit,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),

                      // Info Column
                      Expanded(
                        flex: isWide ? 4 : 0,
                        child: Column(
                          children: const [
                            _ContactInfoCard(
                              icon: Icons.email_outlined,
                              title: 'Direct Support',
                              detail: 'support@edusphere.io',
                              subtext: 'Average response under 2 hours',
                            ),
                            SizedBox(height: 14),
                            _ContactInfoCard(
                              icon: Icons.schedule_outlined,
                              title: 'Operational Hours',
                              detail: 'Mon – Fri: 9:00 AM – 6:00 PM UTC',
                              subtext: '24/7 automated ledger verification',
                            ),
                            SizedBox(height: 14),
                            _ContactInfoCard(
                              icon: Icons.location_on_outlined,
                              title: 'Global Headquarters',
                              detail: 'EduSphere Learning Technologies',
                              subtext: 'San Francisco, CA & London, UK',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String subtext;

  const _ContactInfoCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondaryFixedDim.withOpacity(0.25),
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Icon(icon, color: AppColors.secondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelSmall.copyWith(color: AppColors.outline)),
                const SizedBox(height: 4),
                Text(detail, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtext, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
