import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class AppProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color progressColor;
  final Color backgroundColor;
  final bool showPercentage;

  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 6.0,
    this.progressColor = AppColors.secondary,
    this.backgroundColor = AppColors.surfaceContainerHigh,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final percentInt = (clamped * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: AppTypography.labelSmall,
              ),
              Text(
                '$percentInt%',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            width: double.infinity,
            color: backgroundColor,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: Container(
                color: progressColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
