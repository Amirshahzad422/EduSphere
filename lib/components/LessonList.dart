import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';

class LessonList extends StatelessWidget {
  final List<ModuleModel> syllabus;
  final String? activeLessonId;
  final List<String> completedLessonIds;
  final void Function(LessonModel lesson)? onLessonSelected;

  const LessonList({
    super.key,
    required this.syllabus,
    this.activeLessonId,
    this.completedLessonIds = const [],
    this.onLessonSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (syllabus.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('No modules available yet.', style: AppTypography.bodyMedium),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: syllabus.length,
      itemBuilder: (context, moduleIndex) {
        final module = syllabus[moduleIndex];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: moduleIndex == 0,
              title: Text(
                module.title,
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${module.lessons.length} lessons',
                style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
              ),
              children: module.lessons.map((lesson) {
                final isActive = lesson.id == activeLessonId;
                final isCompleted = completedLessonIds.contains(lesson.id);

                return InkWell(
                  onTap: () => onLessonSelected?.call(lesson),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: isActive ? AppColors.secondaryFixedDim.withOpacity(0.15) : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : (isActive ? Icons.play_circle_filled : Icons.play_circle_outline),
                          size: 20,
                          color: isCompleted
                              ? AppColors.success
                              : (isActive ? AppColors.secondary : AppColors.outline),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  color: isActive ? AppColors.secondary : AppColors.onSurface,
                                ),
                              ),
                              if (lesson.isPreview) ...[
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryFixedDim.withOpacity(0.3),
                                    borderRadius: AppSpacing.roundedSm,
                                  ),
                                  child: Text(
                                    'Free Preview',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 10,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          lesson.duration,
                          style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
