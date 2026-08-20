import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';

enum ButtonVariant { primary, secondary, outline, ghost, danger }
enum ButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isFullWidth;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final double height = switch (size) {
      ButtonSize.sm => 36.0,
      ButtonSize.md => 46.0,
      ButtonSize.lg => 54.0,
    };

    final EdgeInsets padding = switch (size) {
      ButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12),
      ButtonSize.md => const EdgeInsets.symmetric(horizontal: 20),
      ButtonSize.lg => const EdgeInsets.symmetric(horizontal: 28),
    };

    Color bgColor;
    Color fgColor;
    BorderSide? borderSide;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = AppColors.primary;
        fgColor = AppColors.onPrimary;
        break;
      case ButtonVariant.secondary:
        bgColor = AppColors.secondary;
        fgColor = AppColors.onSecondary;
        break;
      case ButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.outlineVariant, width: 1.2);
        break;
      case ButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = AppColors.onSurfaceVariant;
        break;
      case ButtonVariant.danger:
        bgColor = AppColors.error;
        fgColor = AppColors.onError;
        break;
    }

    Widget content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: size == ButtonSize.sm ? 16 : 18, color: fgColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: fgColor,
                  fontSize: size == ButtonSize.sm ? 13 : 15,
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: onPressed == null ? AppColors.surfaceContainerHigh : bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: borderSide ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          borderRadius: AppSpacing.roundedMd,
          child: Padding(
            padding: padding,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
