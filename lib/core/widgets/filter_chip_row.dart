import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One horizontally-scrollable row of single-select filter pills. Shared
/// across features (campus-events category/organizer rows, matches'
/// faculty/field/degree/year/hobby/language rows) — a pure presentational
/// leaf widget with no feature-specific logic.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labelBuilder,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  /// Maps an option's stored value to its display text. Lets callers show a
  /// translated label while [options]/[selected]/[onSelected] keep working in
  /// the canonical values the database stores.
  final String Function(String value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selected;
          return ChoiceChip(
            label: Text(labelBuilder?.call(option) ?? option),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            showCheckmark: false,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? AppColors.primaryForeground
                  : AppColors.foreground,
            ),
            backgroundColor: AppColors.muted,
            selectedColor: AppColors.primary,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}
