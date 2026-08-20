import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';

class AppSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hint = 'Search for courses, skills, or instructors...',
    this.onChanged,
    this.onFilterTap,
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    _internalController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    } else {
      _internalController.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _internalController.text.isNotEmpty;

    return Container(
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
      child: TextField(
        controller: _internalController,
        onChanged: widget.onChanged,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.outline),
          prefixIcon: const Icon(Icons.search, color: AppColors.outline),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: AppColors.outline),
                  onPressed: () {
                    _internalController.clear();
                    widget.onChanged?.call('');
                  },
                  tooltip: 'Clear search',
                ),
              if (widget.onFilterTap != null)
                IconButton(
                  icon: const Icon(Icons.tune, color: AppColors.secondary),
                  onPressed: widget.onFilterTap,
                  tooltip: 'Filter options',
                ),
            ],
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
