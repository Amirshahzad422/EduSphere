import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../components/Testimonials.dart';
import '../utils/helpers.dart';

// Note: No Stitch reference found for About screen — used consistent styling matching lib/styles/
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final TextEditingController _faqSearchCtrl = TextEditingController();
  int? _expandedFaqIndex;

  final List<Map<String, String>> _faqItems = const [
    {
      'question': 'How does EduSphere protect video and course content without paid servers?',
      'answer':
          'EduSphere leverages Cloudinary authenticated media delivery orchestrated by serverless Cloudflare Workers. Non-preview lesson streams are dynamically signed with HMAC-SHA1 tokens only after verifying active Firestore enrollment records, ensuring 100% security with zero paid server costs.',
    },
    {
      'question': 'Are the certificates accredited and verifiable outside the app?',
      'answer':
          'Yes! Every certificate issued generates an immutable verification ID and QR code hosted publicly on Cloudflare Workers and Cloudinary. Anyone can verify your credential by scanning the QR code or visiting the public ledger link.',
    },
    {
      'question': 'How do live classes work?',
      'answer':
          'Instructors schedule and broadcast interactive live classes directly using our embedded Jitsi Meet integration. Enrolled students receive real-time notifications and can participate via video, voice, and live Firestore chat.',
    },
    {
      'question': 'Can instructors earn revenue on EduSphere?',
      'answer':
          'Absolutely. Instructors retain 85% of all gross course sales. Payout balances and transaction logs update in real time with test/live Stripe integrations.',
    },
  ];

  @override
  void dispose() {
    _faqSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppHelpers.isDesktop(context);
    final searchQuery = _faqSearchCtrl.text.toLowerCase().trim();

    final filteredFaqs = _faqItems.where((f) {
      if (searchQuery.isEmpty) return true;
      return f['question']!.toLowerCase().contains(searchQuery) ||
          f['answer']!.toLowerCase().contains(searchQuery);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
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

              // Hero Title
              Text(
                'About EduSphere',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: isDesktop ? 36 : 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'An advanced architectural e-learning platform bridging the gap between theory and industry-grade engineering mastery.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 32),

              // Stats Counter Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = constraints.maxWidth >= 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: crossCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: constraints.maxWidth >= 800 ? 1.4 : 2.0,
                    children: const [
                      _StatCard(value: '12,500+', label: 'Active Students', icon: Icons.people_outline),
                      _StatCard(value: '100+', label: 'Specialized Courses', icon: Icons.menu_book),
                      _StatCard(value: '99.4%', label: 'Positive Rating', icon: Icons.star_outline),
                      _StatCard(value: '100%', label: 'Zero-Card Scalable', icon: Icons.cloud_done_outlined),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),

              // Mission & Vision Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                  boxShadow: const [
                    BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixedDim.withOpacity(0.3),
                            borderRadius: AppSpacing.roundedMd,
                          ),
                          child: const Icon(Icons.rocket_launch, color: AppColors.secondary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Text('Our Core Mission', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'EduSphere democratizes technical education by empowering top industry architects to publish, stream, and monetize world-class engineering masterclasses with immutable blockchain-verifiable credentials and zero barrier to entry.',
                      style: AppTypography.bodyMedium.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Architectural Pillars
              Text('Architectural Pillars', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  return GridView.count(
                    crossAxisCount: isWide ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isWide ? 1.8 : 2.2,
                    children: const [
                      _PillarCard(
                        title: 'Zero-Card Serverless Edge',
                        description: 'Cloudflare Workers & Cloudinary free-tier architecture providing secure signed delivery.',
                        icon: Icons.shield_outlined,
                      ),
                      _PillarCard(
                        title: 'Verifiable Credentials',
                        description: 'Tamper-proof PDF certificates with unique cryptographic verification IDs and QR codes.',
                        icon: Icons.workspace_premium_outlined,
                      ),
                      _PillarCard(
                        title: 'Live Interactive Streaming',
                        description: 'Low-latency live classrooms with integrated chat, raise-hand, and participant moderation.',
                        icon: Icons.videocam_outlined,
                      ),
                      _PillarCard(
                        title: 'Gamified Scholar Growth',
                        description: 'Dynamic XP earning, consecutive learning streaks, achievement badges, and global rankings.',
                        icon: Icons.bolt,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),

              // Searchable FAQ Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Frequently Asked Questions', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _faqSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search FAQ topics (e.g. video security, certificates)...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedMd,
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              if (filteredFaqs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('No FAQs matching "${_faqSearchCtrl.text}"', style: AppTypography.bodyMedium),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredFaqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filteredFaqs[index];
                    final isExpanded = _expandedFaqIndex == index;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: isExpanded ? AppColors.secondary : AppColors.surfaceContainerHigh),
                      ),
                      child: ExpansionTile(
                        key: PageStorageKey('faq_$index'),
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedFaqIndex = expanded ? index : null;
                          });
                        },
                        title: Text(
                          item['question']!,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isExpanded ? AppColors.secondary : AppColors.onSurface,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              item['answer']!,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 48),

              // Student Testimonials Carousel
              Text('What Students Say', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              const TestimonialsWidget(),
              const SizedBox(height: 48),

              // Bottom Call to Action
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppSpacing.roundedXl,
                ),
                child: Column(
                  children: [
                    Text(
                      'Ready to Master Advanced Skills?',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Join over 12,000 engineers and creators advancing their careers today.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Explore Masterclasses',
                      variant: ButtonVariant.secondary,
                      size: ButtonSize.lg,
                      icon: Icons.explore,
                      onPressed: () => context.go('/courses'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.secondary, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.outline)),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _PillarCard({required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: AppColors.secondaryFixedDim.withOpacity(0.2),
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Icon(icon, color: AppColors.secondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(description, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
