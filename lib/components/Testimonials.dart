import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';

class TestimonialItem {
  final String name;
  final String role;
  final String avatarUrl;
  final String comment;
  final double rating;

  const TestimonialItem({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.comment,
    this.rating = 5.0,
  });
}

class TestimonialsWidget extends StatelessWidget {
  final List<TestimonialItem> testimonials;

  const TestimonialsWidget({
    super.key,
    this.testimonials = const [
      TestimonialItem(
        name: 'Samantha Lee',
        role: 'Mobile Dev Lead @ ScaleUp',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        comment: 'EduSphere revolutionized the way our engineering team upskills. The Flutter and Cloud curricula are world-class!',
        rating: 5.0,
      ),
      TestimonialItem(
        name: 'David Chen',
        role: 'Product Designer @ FinTech Co',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        comment: 'The design systems course gave me concrete skills I applied on day one. Truly an incredible learning experience.',
        rating: 5.0,
      ),
      TestimonialItem(
        name: 'Amina Zahra',
        role: 'AI Researcher',
        avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200',
        comment: 'The hands-on LLM projects and live discussions with instructors are unmatched anywhere else.',
        rating: 5.0,
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: testimonials.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = testimonials[index];
              return Container(
                width: 320,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(item.avatarUrl),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                item.role,
                                style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (starIndex) => const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"${item.comment}"',
                      style: AppTypography.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
